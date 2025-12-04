#!/usr/bin/env python3
"""
Batch Process Samples - Enrich All Metadata Files

This script processes all samples in the samples/ directory and enriches
their metadata.json files with comprehensive metrics.

Usage:
    python .claude/scripts/batch_enrich.py
    python .claude/scripts/batch_enrich.py --dry-run
    python .claude/scripts/batch_enrich.py --tasks task-1 task-2 task-3
"""

import sys
import os
from pathlib import Path
import subprocess

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

from enrich_metadata import MetadataEnricher


def main():
    dry_run = '--dry-run' in sys.argv
    
    # Determine which tasks to process
    if '--tasks' in sys.argv:
        idx = sys.argv.index('--tasks')
        task_names = sys.argv[idx + 1:]
        task_dirs = [Path('samples') / task for task in task_names]
    else:
        # Process all tasks
        samples_dir = Path('samples')
        if not samples_dir.exists():
            print("❌ Error: samples/ directory not found")
            sys.exit(1)
        
        task_dirs = sorted([d for d in samples_dir.iterdir() if d.is_dir() and d.name.startswith('task-')])
    
    if not task_dirs:
        print("❌ No task directories found")
        sys.exit(1)
    
    print(f"{'🔍 DRY RUN: ' if dry_run else ''}Processing {len(task_dirs)} samples...")
    print("=" * 70)
    
    success_count = 0
    error_count = 0
    
    for task_dir in task_dirs:
        print(f"\n📂 {task_dir.name}")
        
        if not (task_dir / 'metadata.json').exists():
            print(f"  ⚠️  Skipping - no metadata.json found")
            continue
        
        if dry_run:
            print(f"  ✓ Would enrich metadata")
            success_count += 1
            continue
        
        try:
            enricher = MetadataEnricher(str(task_dir))
            enricher.save()
            success_count += 1
        except Exception as e:
            print(f"  ❌ Error: {e}")
            error_count += 1
    
    print("\n" + "=" * 70)
    print(f"✅ Successfully enriched: {success_count}")
    if error_count > 0:
        print(f"❌ Errors: {error_count}")
    
    return 0 if error_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())

