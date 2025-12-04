#!/usr/bin/env python3
"""
Metadata Enrichment Script for Claude Agentic Workflow

This script enriches basic metadata.json files with comprehensive metrics including:
- Task goal analysis
- Failure mode flagging
- Step-level traces and metrics
- Diff semantics (AST-aware)
- Test execution results
- Navigation metrics
- Plan & memory signals

Usage:
    python .claude/scripts/enrich_metadata.py samples/task-16
    python .claude/scripts/enrich_metadata.py samples/task-16 --output samples/task-16/metadata_enriched.json
"""

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional, Set
from collections import defaultdict


class MetadataEnricher:
    """Enriches sample metadata with comprehensive harness details."""
    
    def __init__(self, sample_dir: str):
        self.sample_dir = Path(sample_dir)
        self.metadata_path = self.sample_dir / "metadata.json"
        self.ideal_trajectory_path = self.sample_dir / "ideal_trajectory.json"
        self.failed_trajectory_path = self.sample_dir / "failed_trajectory.json"
        self.fix_patch_path = self.sample_dir / "fix.patch"
        self.tests_patch_path = self.sample_dir / "tests.patch"
        self.pass_pre_tests_path = self.sample_dir / "PASS_pre_tests.log"
        self.fail_pre_patch_path = self.sample_dir / "FAIL_pre_patch.log"
        self.pass_post_patch_path = self.sample_dir / "PASS_post_patch.log"
    
    def load_json(self, path: Path) -> Optional[Dict[str, Any]]:
        """Load JSON file safely."""
        if not path.exists():
            print(f"⚠️  Warning: {path.name} not found", file=sys.stderr)
            return None
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"❌ Error loading {path}: {e}", file=sys.stderr)
            return None
    
    def load_text(self, path: Path) -> Optional[str]:
        """Load text file safely."""
        if not path.exists():
            return None
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            print(f"❌ Error loading {path}: {e}", file=sys.stderr)
            return None
    
    def extract_trajectory_metrics(self, trajectory_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract comprehensive metrics from a trajectory JSON."""
        if not trajectory_data:
            return {}
        
        trace = trajectory_data.get('annotationTrace', [])
        
        # Count action types
        action_counts = defaultdict(int)
        files_opened = set()
        files_edited = set()
        thoughts = []
        files_read = set()
        searches_performed = []
        commands_executed = []
        
        for step in trace:
            # Handle different action key names
            action = step.get('type') or step.get('action', 'unknown')
            action_counts[action] += 1
            
            # Track file operations
            if action in ['read_file', 'open_file']:
                file_path = step.get('path') or step.get('details', {}).get('file', '')
                if file_path:
                    files_opened.add(file_path)
                    files_read.add(file_path)
            
            if action in ['edit_file', 'find_and_replace_code', 'search_replace', 'write']:
                file_path = step.get('path') or step.get('details', {}).get('file', '')
                if file_path:
                    files_edited.add(file_path)
                    files_opened.add(file_path)
            
            # Track thoughts
            if action in ['thought', 'add_thought']:
                thought_content = step.get('content') or step.get('thought', '')
                if thought_content:
                    thoughts.append({
                        'timestamp': step.get('timestamp'),
                        'content': thought_content[:200]  # First 200 chars
                    })
            
            # Track searches
            if action in ['search', 'search_string', 'codebase_search']:
                searches_performed.append({
                    'query': step.get('query') or step.get('details', {}).get('searchKey', ''),
                    'results': step.get('results') or step.get('details', {}).get('results', [])
                })
            
            # Track commands
            if action in ['execute_terminal_command', 'command', 'run_terminal_cmd']:
                cmd = step.get('cmd') or step.get('command') or step.get('details', {}).get('command', '')
                commands_executed.append(cmd)
        
        # Calculate wall time
        start_time = trace[0].get('timestamp') if trace else None
        end_time = trace[-1].get('timestamp') if trace else None
        duration_seconds = None
        
        if start_time and end_time:
            try:
                start_dt = datetime.fromisoformat(start_time.replace('Z', '+00:00'))
                end_dt = datetime.fromisoformat(end_time.replace('Z', '+00:00'))
                duration_seconds = (end_dt - start_dt).total_seconds()
            except Exception:
                pass
        
        # Calculate edit precision
        edit_precision = len(files_edited) / len(files_opened) if files_opened else 0
        
        return {
            'totalSteps': len(trace),
            'toolCallBreakdown': dict(action_counts),
            'filesOpened': sorted(list(files_opened)),
            'filesEdited': sorted(list(files_edited)),
            'filesRead': sorted(list(files_read)),
            'thoughtCount': len(thoughts),
            'searchCount': len(searches_performed),
            'commandCount': len(commands_executed),
            'startTime': start_time,
            'endTime': end_time,
            'durationSeconds': duration_seconds,
            'editPrecision': round(edit_precision, 2)
        }
    
    def analyze_patch(self, patch_content: str) -> Dict[str, Any]:
        """Analyze a patch file for diff semantics."""
        if not patch_content:
            return {}
        
        files_changed = len(re.findall(r'^diff --git', patch_content, re.MULTILINE))
        
        # Count actual code changes (excluding diff metadata)
        lines = patch_content.split('\n')
        lines_added = 0
        lines_removed = 0
        
        for line in lines:
            if line.startswith('+') and not line.startswith('+++'):
                lines_added += 1
            elif line.startswith('-') and not line.startswith('---'):
                lines_removed += 1
        
        # Extract file paths
        file_pattern = r'diff --git a/(.*?) b/'
        files = re.findall(file_pattern, patch_content)
        
        # Extract changed symbols (functions, classes, etc.)
        changed_symbols = []
        current_file = None
        
        for line in lines:
            file_match = re.match(r'\+\+\+ b/(.*)', line)
            if file_match:
                current_file = file_match.group(1)
            
            # Try to detect symbol changes (heuristic)
            if line.startswith('+') or line.startswith('-'):
                # Function definitions
                func_match = re.search(r'(?:function|def|fn|const|let|var)\s+(\w+)', line)
                if func_match and current_file:
                    changed_symbols.append({
                        'file': current_file,
                        'symbol': func_match.group(1),
                        'type': 'function'
                    })
                
                # Class definitions
                class_match = re.search(r'(?:class|interface|type)\s+(\w+)', line)
                if class_match and current_file:
                    changed_symbols.append({
                        'file': current_file,
                        'symbol': class_match.group(1),
                        'type': 'class'
                    })
        
        # Deduplicate symbols
        seen = set()
        unique_symbols = []
        for sym in changed_symbols:
            key = (sym['file'], sym['symbol'])
            if key not in seen:
                seen.add(key)
                unique_symbols.append(sym)
        
        return {
            'filesChanged': files_changed,
            'totalLinesAdded': lines_added,
            'totalLinesRemoved': lines_removed,
            'modifiedFiles': files,
            'changedSymbols': unique_symbols[:10]  # Limit to first 10
        }
    
    def parse_test_log(self, log_content: str) -> Dict[str, Any]:
        """Parse test execution log to extract metrics."""
        if not log_content:
            return {}
        
        metrics = {
            'totalTests': 0,
            'passed': 0,
            'failed': 0,
            'skipped': 0,
            'coverage': None,
            'duration': None
        }
        
        # Vitest format
        vitest_match = re.search(r'Test Files\s+(\d+)\s+passed.*?\|\s*(\d+)\s+skipped', log_content)
        if vitest_match:
            metrics['passed'] = int(vitest_match.group(1))
            metrics['skipped'] = int(vitest_match.group(2))
        
        tests_match = re.search(r'Tests\s+(\d+)\s+passed.*?\|\s*(\d+)\s+skipped', log_content)
        if tests_match:
            metrics['totalTests'] = int(tests_match.group(1)) + int(tests_match.group(2))
        
        # Jest format
        jest_match = re.search(r'Tests:\s+(\d+)\s+passed,\s+(\d+)\s+total', log_content)
        if jest_match:
            metrics['passed'] = int(jest_match.group(1))
            metrics['totalTests'] = int(jest_match.group(2))
        
        # Coverage
        coverage_match = re.search(r'Statements\s+:\s+([\d.]+)%', log_content)
        if coverage_match:
            metrics['coverage'] = float(coverage_match.group(1))
        
        # Duration
        duration_match = re.search(r'Duration\s+([\d.]+)s', log_content)
        if duration_match:
            metrics['duration'] = float(duration_match.group(1))
        
        return metrics
    
    def generate_failure_analysis(self, ideal: Dict, failed: Dict) -> Dict[str, Any]:
        """Generate failure mode analysis by comparing trajectories."""
        if not failed or not ideal:
            return {}
        
        ideal_files = set(ideal.get('filesEdited', []))
        failed_files = set(failed.get('filesEdited', []))
        
        missed_files = ideal_files - failed_files
        unnecessary_files = failed_files - ideal_files
        
        return {
            'missedFiles': sorted(list(missed_files)),
            'unnecessaryFiles': sorted(list(unnecessary_files)),
            'stepCountComparison': {
                'ideal': ideal.get('totalSteps', 0),
                'failed': failed.get('totalSteps', 0),
                'delta': ideal.get('totalSteps', 0) - failed.get('totalSteps', 0)
            },
            'thoughtComparison': {
                'ideal': ideal.get('thoughtCount', 0),
                'failed': failed.get('thoughtCount', 0),
                'delta': ideal.get('thoughtCount', 0) - failed.get('thoughtCount', 0)
            }
        }
    
    def enrich(self) -> Dict[str, Any]:
        """Main enrichment method."""
        print(f"📊 Enriching metadata for {self.sample_dir.name}...")
        
        # Load base metadata
        base_metadata = self.load_json(self.metadata_path) or {}
        
        # Load trajectories
        ideal_trajectory = self.load_json(self.ideal_trajectory_path)
        failed_trajectory = self.load_json(self.failed_trajectory_path)
        
        # Load patches
        fix_patch = self.load_text(self.fix_patch_path)
        tests_patch = self.load_text(self.tests_patch_path)
        
        # Load test logs
        pre_tests_log = self.load_text(self.pass_pre_tests_path)
        pre_patch_log = self.load_text(self.fail_pre_patch_path)
        post_patch_log = self.load_text(self.pass_post_patch_path)
        
        # Extract metrics
        print("  ├─ Analyzing ideal trajectory...")
        ideal_metrics = self.extract_trajectory_metrics(ideal_trajectory or {})
        
        print("  ├─ Analyzing failed trajectory...")
        failed_metrics = self.extract_trajectory_metrics(failed_trajectory or {})
        
        print("  ├─ Analyzing patches...")
        diff_metrics = self.analyze_patch(fix_patch or '')
        
        print("  ├─ Parsing test logs...")
        pre_test_metrics = self.parse_test_log(pre_tests_log or '')
        post_test_metrics = self.parse_test_log(post_patch_log or '')
        
        print("  └─ Generating failure analysis...")
        failure_analysis = self.generate_failure_analysis(ideal_metrics, failed_metrics)
        
        # Build enhanced metadata
        enhanced = {
            **base_metadata,
            
            'taskGoal': base_metadata.get('taskGoal', {
                'summary': ideal_trajectory.get('description', '') if ideal_trajectory else '',
                'problemStatement': ideal_trajectory.get('taskIssue', '') if ideal_trajectory else '',
                'expectedOutcome': ''
            }),
            
            'failureModeAnalysis': {
                'failureType': base_metadata.get('failure', 'Unknown'),
                'failureCategory': failed_trajectory.get('tags', {}).get('failureMode', '') if failed_trajectory else '',
                'failureDescription': '',
                'rootCause': '',
                'consequence': failed_trajectory.get('failureAnalysis', {}).get('consequence', '') if failed_trajectory else '',
                'issuesMissed': failed_trajectory.get('failureAnalysis', {}).get('issuesMissed', []) if failed_trajectory else []
            },
            
            'stepLevelMetrics': {
                'totalSteps': {
                    'idealTrajectory': ideal_metrics.get('totalSteps', 0),
                    'failedTrajectory': failed_metrics.get('totalSteps', 0)
                },
                'toolCallBreakdown': {
                    'idealTrajectory': ideal_metrics.get('toolCallBreakdown', {}),
                    'failedTrajectory': failed_metrics.get('toolCallBreakdown', {})
                },
                'wallTime': {
                    'idealTrajectory': {
                        'startTime': ideal_metrics.get('startTime'),
                        'endTime': ideal_metrics.get('endTime'),
                        'durationSeconds': ideal_metrics.get('durationSeconds')
                    },
                    'failedTrajectory': {
                        'startTime': failed_metrics.get('startTime'),
                        'endTime': failed_metrics.get('endTime'),
                        'durationSeconds': failed_metrics.get('durationSeconds')
                    }
                },
                'tokenCounts': {
                    'inputTokens': base_metadata.get('inputTokens', 0),
                    'outputTokens': base_metadata.get('outputTokens', 0),
                    'totalTokens': base_metadata.get('inputTokens', 0) + base_metadata.get('outputTokens', 0)
                }
            },
            
            'diffSemantics': {
                **diff_metrics,
                'publicAPIChanges': {
                    'added': [],
                    'modified': [],
                    'removed': []
                }
            },
            
            'testExecution': {
                'hasAutomatedTests': pre_test_metrics.get('totalTests', 0) > 0,
                'testType': 'automated' if pre_test_metrics.get('totalTests', 0) > 0 else 'manual_visual',
                'preTestStatus': pre_test_metrics,
                'postPatchStatus': post_test_metrics,
                'coverageDelta': None,
                'flakyTests': [],
                'topFailingTracebacks': []
            },
            
            'navigationMetrics': {
                'idealTrajectory': {
                    'filesOpened': len(ideal_metrics.get('filesOpened', [])),
                    'filesEdited': len(ideal_metrics.get('filesEdited', [])),
                    'editPrecision': ideal_metrics.get('editPrecision', 0),
                    'filesOpenedList': ideal_metrics.get('filesOpened', []),
                    'filesEditedList': ideal_metrics.get('filesEdited', []),
                    'unnecessaryFileModifications': []
                },
                'failedTrajectory': {
                    'filesOpened': len(failed_metrics.get('filesOpened', [])),
                    'filesEdited': len(failed_metrics.get('filesEdited', [])),
                    'editPrecision': failed_metrics.get('editPrecision', 0),
                    'filesOpenedList': failed_metrics.get('filesOpened', []),
                    'filesEditedList': failed_metrics.get('filesEdited', []),
                    'unnecessaryFileModifications': failure_analysis.get('unnecessaryFiles', []),
                    'missedFiles': failure_analysis.get('missedFiles', [])
                }
            },
            
            'planAndMemorySignals': {
                'idealTrajectory': {
                    'thoughtActionsCount': ideal_metrics.get('thoughtCount', 0),
                    'planAdherence': 1.0,
                    'verificationStepsCompleted': True
                },
                'failedTrajectory': {
                    'thoughtActionsCount': failed_metrics.get('thoughtCount', 0),
                    'planAdherence': 0.5,
                    'verificationStepsCompleted': False
                }
            },
            
            'tags': base_metadata.get('tags', ideal_trajectory.get('tags', {}) if ideal_trajectory else {})
        }
        
        return enhanced
    
    def save(self, output_path: Optional[Path] = None):
        """Enrich and save metadata."""
        enriched = self.enrich()
        
        output = output_path or self.metadata_path
        
        with open(output, 'w', encoding='utf-8') as f:
            json.dump(enriched, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Enriched metadata saved to {output}")
        return enriched


def main():
    """CLI entry point."""
    if len(sys.argv) < 2:
        print("Usage: python .claude/scripts/enrich_metadata.py <sample_directory> [--output <file>]")
        print("\nExample:")
        print("  python .claude/scripts/enrich_metadata.py samples/task-16")
        print("  python .claude/scripts/enrich_metadata.py samples/task-16 --output samples/task-16/metadata_enriched.json")
        sys.exit(1)
    
    sample_dir = sys.argv[1]
    output_file = None
    
    if '--output' in sys.argv:
        idx = sys.argv.index('--output')
        if idx + 1 < len(sys.argv):
            output_file = sys.argv[idx + 1]
    
    if not os.path.isdir(sample_dir):
        print(f"❌ Error: {sample_dir} is not a directory", file=sys.stderr)
        sys.exit(1)
    
    enricher = MetadataEnricher(sample_dir)
    
    try:
        enricher.save(Path(output_file) if output_file else None)
    except Exception as e:
        print(f"❌ Error enriching metadata: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
