# Code Coverage Quick Reference

**Purpose:** Fast lookup for code coverage commands across different languages and frameworks.

---

## JavaScript/TypeScript

### Vitest (Recommended for modern projects)

```bash
# Summary coverage report (for pre-tests)
vitest run --coverage --coverage.reporter=text-summary --silent --reporter=dot

# Detailed coverage report (for post-patch)
vitest run --coverage --coverage.reporter=text --silent --reporter=dot

# Coverage with specific file inclusion
vitest run --coverage --coverage.include="src/lib/**/*.ts" --coverage.reporter=text
```

**Expected Output:**
```
% Coverage report from v8
=============================== Coverage summary ===============================
Statements   : 88.8% ( 52349/148711 )
Branches     : 82.77% ( 12091/14607 )
Functions    : 62.68% ( 3557/5674 )
Lines        : 88.8% ( 52349/148711 )
================================================================================
```

**Configuration (vitest.config.ts):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8', // or 'istanbul'
      reporter: ['text', 'text-summary', 'html'],
      exclude: ['node_modules/', 'dist/', '**/*.test.ts']
    }
  }
})
```

---

### Jest (Legacy projects)

```bash
# Basic coverage
jest --coverage

# With specific reporters
jest --coverage --coverageReporters=text --coverageReporters=text-summary

# Silent mode with coverage
jest --coverage --silent
```

**Expected Output:**
```
------------|---------|----------|---------|---------|-------------------
File        | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s 
------------|---------|----------|---------|---------|-------------------
All files   |   88.8  |    88.23 |   84.21 |    88.8 |                   
 index.ts   |     100 |      100 |     100 |     100 |                   
------------|---------|----------|---------|---------|-------------------
```

---

## Python

### pytest with pytest-cov

```bash
# Basic coverage
pytest --cov=./ --cov-report=term tests/

# With verbose output
pytest -v --cov=./ --cov-report=term tests/

# Multi-process tests with coverage
pytest -n 3 --cov=./ --cov-report=term --cov-report=xml tests/

# Specific test file with coverage
pytest --cov=myapp --cov-report=term tests/test_myapp.py
```

**Expected Output:**
```
================================ tests coverage ================================
_______________ coverage: platform linux, python 3.11.14-final-0 _______________

Name                                    Stmts   Miss  Cover
-----------------------------------------------------------
myapp/__init__.py                           1      0   100%
myapp/models.py                            88      5    94%
myapp/views.py                            104     62    40%
-----------------------------------------------------------
TOTAL                                   66814  45589    32%
Coverage XML written to file coverage.xml
```

**Installation:**
```bash
pip install pytest pytest-cov
```

**Configuration (pyproject.toml or setup.cfg):**
```ini
[tool:pytest]
addopts = --cov=. --cov-report=term --cov-report=html
```

---

## Go

### go test with coverage

```bash
# Basic coverage (inline percentages)
go test -v -cover ./...

# Detailed coverage profile
go test -v -cover -coverprofile=coverage.out ./...

# Display coverage summary
go tool cover -func=coverage.out

# Combined (for run.sh scripts)
go test -v -cover -coverprofile=coverage.out ./... && go tool cover -func=coverage.out

# HTML coverage report (optional)
go tool cover -html=coverage.out -o coverage.html
```

**Expected Output:**
```
# Basic -cover flag:
ok  	github.com/user/repo/pkg/handlers	0.123s	coverage: 85.5% of statements
ok  	github.com/user/repo/pkg/models	0.089s	coverage: 92.3% of statements

# With go tool cover -func:
github.com/user/repo/pkg/handlers/payment.go:25:	HandlePayment		85.7%
github.com/user/repo/pkg/handlers/user.go:15:		GetUser			100.0%
github.com/user/repo/pkg/models/order.go:10:		CreateOrder		78.5%
total:							(statements)		87.2%
```

**Notes:**
- `-cover` provides inline percentages per package
- `-coverprofile=coverage.out` creates detailed coverage data
- `go tool cover -func` displays function-level coverage
- No additional dependencies needed (built into Go toolchain)

---

## Java

### Maven with JaCoCo

**pom.xml configuration:**
```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.10</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

**Commands:**
```bash
# Run tests with coverage
mvn test jacoco:report

# View coverage from terminal (extract from HTML)
mvn test jacoco:report && cat target/site/jacoco/index.html | grep -A10 "Total"

# Alternative: Use jacoco-maven-plugin with console output
mvn test jacoco:report jacoco:check
```

**Expected Output Location:**
- HTML Report: `target/site/jacoco/index.html`
- XML Report: `target/site/jacoco/jacoco.xml`
- CSV Report: `target/site/jacoco/jacoco.csv`

**Console extraction:**
```bash
# Extract coverage summary
echo "JaCoCo Coverage Report:"
grep -A5 "Total" target/site/jacoco/index.html | sed 's/<[^>]*>//g'
```

---

### Gradle with JaCoCo

**build.gradle configuration:**
```groovy
plugins {
    id 'java'
    id 'jacoco'
}

jacoco {
    toolVersion = "0.8.10"
}

test {
    finalizedBy jacocoTestReport
}

jacocoTestReport {
    dependsOn test
    reports {
        xml.required = true
        html.required = true
        csv.required = false
    }
}

jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = 0.80
            }
        }
    }
}
```

**Commands:**
```bash
# Run tests with coverage
gradle test jacocoTestReport

# View coverage summary
gradle test jacocoTestReport && cat build/reports/jacoco/test/html/index.html | grep -A10 "Total"

# Run tests and verify coverage thresholds
gradle test jacocoTestCoverageVerification
```

**Expected Output Location:**
- HTML Report: `build/reports/jacoco/test/html/index.html`
- XML Report: `build/reports/jacoco/test/jacocoTestReport.xml`

---

## Rust

### cargo with tarpaulin or llvm-cov

**Using cargo-tarpaulin:**
```bash
# Install
cargo install cargo-tarpaulin

# Run with coverage
cargo tarpaulin --out Stdout --output-dir coverage/

# Verbose output
cargo tarpaulin -v --out Stdout
```

**Using llvm-cov (built-in nightly):**
```bash
# Install llvm-tools
rustup component add llvm-tools-preview

# Run tests with coverage
cargo +nightly test --all-features --no-fail-fast -- --nocapture
LLVM_PROFILE_FILE="coverage-%p-%m.profraw" cargo +nightly test

# Generate report
cargo +nightly llvm-cov --html
```

**Expected Output:**
```
|| Tested/Total Lines:
|| src/lib.rs: 45/50
|| src/main.rs: 120/135
||
88.5% coverage, 165/185 lines covered
```

---

## Ruby

### RSpec with SimpleCov

**spec/spec_helper.rb:**
```ruby
require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  # ...
end
```

**Commands:**
```bash
# Run tests with coverage
bundle exec rspec

# Coverage report location: coverage/index.html
```

**Console output:**
```
Coverage report generated for RSpec to /app/coverage.
123 / 145 LOC (84.83%) covered.
```

---

## PHP

### PHPUnit with code coverage

```bash
# With Xdebug
phpunit --coverage-text

# With PCOV (faster)
phpunit --coverage-text --coverage-html coverage/

# Detailed output
phpunit --coverage-text --colors=always
```

**Expected Output:**
```
Code Coverage Report:
  2023-12-03 10:15:30

 Summary:
  Classes: 85.00% (17/20)
  Methods: 88.24% (45/51)
  Lines:   82.15% (234/285)
```

---

## C/C++

### gcov/lcov

```bash
# Compile with coverage flags
g++ -fprofile-arcs -ftest-coverage -o myapp myapp.cpp

# Run tests
./myapp

# Generate coverage report
gcov myapp.cpp
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage/
```

---

## Common Patterns

### Coverage Thresholds

**Typical coverage goals:**
- **Statement Coverage:** 80%+ (good), 90%+ (excellent)
- **Branch Coverage:** 70%+ (good), 85%+ (excellent)
- **Function Coverage:** 85%+ (good), 95%+ (excellent)
- **Line Coverage:** 80%+ (good), 90%+ (excellent)

### Coverage in CI/CD

```bash
# Generate coverage and fail if below threshold
pytest --cov=. --cov-fail-under=80

# Go with coverage check
go test -cover ./... | grep -v "100.0%"

# JavaScript with threshold
jest --coverage --coverageThreshold='{"global":{"statements":80}}'
```

---

## Troubleshooting

### Issue: No coverage output

**Solution:**
1. Verify coverage tool is installed
2. Check test command includes coverage flag
3. Ensure tests are actually running
4. Check for output redirection issues

### Issue: Coverage shows 0%

**Solution:**
1. Verify source code is being executed
2. Check coverage includes correct paths
3. Ensure instrumentation is enabled
4. Look for build/transpilation issues

### Issue: Coverage incomplete

**Solution:**
1. Include all source files in coverage config
2. Check for excluded directories
3. Verify all test suites are running
4. Look for source map issues (JS/TS)

---

## Quick Command Reference

| Language   | Command                                              | Output Format |
|------------|------------------------------------------------------|---------------|
| JS/TS      | `vitest run --coverage --coverage.reporter=text`    | Text table    |
| Python     | `pytest --cov=./ --cov-report=term`                  | Text table    |
| Go         | `go test -cover ./...`                               | Inline %      |
| Java       | `mvn test jacoco:report`                             | HTML/XML      |
| Ruby       | `bundle exec rspec` (with SimpleCov)                 | HTML          |
| PHP        | `phpunit --coverage-text`                            | Text table    |
| Rust       | `cargo tarpaulin --out Stdout`                       | Text          |
| C/C++      | `gcov *.cpp`                                         | Text files    |

---

## For Sample Creation

**Always ensure:**
1. ✅ PASS_pre_tests.log includes coverage
2. ✅ PASS_post_patch.log includes coverage
3. ✅ Coverage is human-readable text in logs
4. ✅ Both statement and branch coverage shown
5. ✅ Coverage tools installed in Dockerfile

**Do NOT:**
- ❌ Only generate binary/XML coverage (include text)
- ❌ Skip coverage in pre-tests phase
- ❌ Use coverage only for specific files (use full project)
- ❌ Hide coverage output with --silent without reporter

