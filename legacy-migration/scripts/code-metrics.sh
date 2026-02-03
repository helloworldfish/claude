#!/bin/bash

# Code Metrics Analysis Script for Legacy Migration
# This script analyzes code complexity, quality metrics, and technical debt

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/code-metrics}"
PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create output directory
create_output_directory() {
    log_info "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"/{raw-data,reports,metrics}
}

# Detect project type
detect_project_type() {
    log_info "Detecting project type..."

    if [[ -f "$PROJECT_PATH/pom.xml" ]]; then
        PROJECT_TYPE="java"
        log_success "Detected Java project"
    elif [[ -f "$PROJECT_PATH/package.json" ]]; then
        PROJECT_TYPE="javascript"
        log_success "Detected JavaScript/Node.js project"
    elif [[ -f "$PROJECT_PATH/requirements.txt" || -f "$PROJECT_PATH/setup.py" ]]; then
        PROJECT_TYPE="python"
        log_success "Detected Python project"
    else
        PROJECT_TYPE="generic"
        log_warning "Could not detect specific project type, using generic analysis"
    fi
}

# Count lines of code
count_lines_of_code() {
    log_info "Counting lines of code..."

    # Define file extensions to include
    declare -A extensions=(
        ["java"]="java"
        ["javascript"]="js jsx ts tsx"
        ["python"]="py"
        ["typescript"]="ts tsx"
        ["go"]="go"
        ["ruby"]="rb"
        ["php"]="php"
        ["cpp"]="cpp cxx cc"
        ["c"]="c"
        ["csharp"]="cs"
        ["sql"]="sql"
        ["html"]="html htm"
        ["css"]="css scss sass"
        ["xml"]="xml"
        ["yaml"]="yaml yml"
        ["json"]="json"
        ["markdown"]="md"
    )

    total_files=0
    total_lines=0
    total_blank=0
    total_comment=0
    total_code=0

    # Create detailed breakdown
    {
        echo "Language,Files,Lines,Blank Lines,Comments,Code Lines"

        for lang in "${!extensions[@]}"; do
            exts=(${extensions[$lang]})
            file_count=0
            line_count=0
            blank_count=0
            comment_count=0
            code_count=0

            for ext in "${exts[@]}"; do
                while IFS= read -r -d '' file; do
                    ((file_count++))

                    # Count lines using cloc if available, otherwise use wc
                    if command -v cloc &> /dev/null; then
                        stats=$(cloc "$file" --csv 2>/dev/null | tail -1)
                        IFS=',' read -ra STATS <<< "$stats"
                        if [[ ${#STATS[@]} -ge 5 ]]; then
                            ((line_count += STATS[1]))
                            ((blank_count += STATS[2]))
                            ((comment_count += STATS[3]))
                            ((code_count += STATS[4]))
                        fi
                    else
                        # Fallback to simple line counting
                        lines=$(wc -l < "$file")
                        ((line_count += lines))
                        ((code_count += lines))
                    fi
                done < <(find "$PROJECT_PATH" -name "*.$ext" -type f -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/build/*" -not -path "*/.git/*" -print0)
            done

            if [[ $file_count -gt 0 ]]; then
                echo "$lang,$file_count,$line_count,$blank_count,$comment_count,$code_count"
                ((total_files += file_count))
                ((total_lines += line_count))
                ((total_blank += blank_count))
                ((total_comment += comment_count))
                ((total_code += code_count))
            fi
        done

        echo "TOTAL,$total_files,$total_lines,$total_blank,$total_comment,$total_code"
    } > "$OUTPUT_DIR/raw-data/loc-breakdown.csv"

    log_success "Lines of code analysis completed"
    log_info "Total files analyzed: $total_files"
    log_info "Total lines of code: $total_lines"
}

# Analyze Java code complexity
analyze_java_complexity() {
    log_info "Analyzing Java code complexity..."

    if ! command -v java &> /dev/null; then
        log_warning "Java not found. Skipping Java-specific analysis."
        return
    fi

    # Create Java complexity analyzer
    cat > "$OUTPUT_DIR/JavaComplexityAnalyzer.java" << 'EOF'
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import java.util.stream.*;

public class JavaComplexityAnalyzer {
    private static final Pattern CLASS_PATTERN = Pattern.compile("class\\s+(\\w+)");
    private static final Pattern METHOD_PATTERN = Pattern.compile("(?:public|private|protected|static|final|native|synchronized|abstract|transient|volatile)\\s+[^\\s]*\\s+(\\w+)\\s*\\(");
    private static final Pattern CYCLOMATIC_PATTERN = Pattern.compile("\\b(if|for|while|case|catch|&&|\\|\\|)\\b");

    private int totalClasses = 0;
    private int totalMethods = 0;
    private int totalComplexity = 0;
    private int maxMethodComplexity = 0;
    private String mostComplexMethod = "";
    private Map<String, Integer> classComplexities = new HashMap<>();

    public void analyzeDirectory(Path projectPath) throws IOException {
        Files.walk(projectPath)
            .filter(p -> p.toString().endsWith(".java"))
            .filter(p -> !p.toString().contains("/target/"))
            .filter(p -> !p.toString().contains("/build/"))
            .forEach(this::analyzeFile);
    }

    private void analyzeFile(Path filePath) {
        try {
            String content = Files.readString(filePath);
            analyzeFile(content, filePath.toString());
        } catch (IOException e) {
            System.err.println("Error reading file: " + filePath);
        }
    }

    private void analyzeFile(String content, String fileName) {
        Matcher classMatcher = CLASS_PATTERN.matcher(content);
        String currentClass = "Unknown";

        while (classMatcher.find()) {
            currentClass = classMatcher.group(1);
            totalClasses++;
            classComplexities.put(currentClass, 0);
        }

        Matcher methodMatcher = METHOD_PATTERN.matcher(content);
        while (methodMatcher.find()) {
            String methodName = methodMatcher.group(1);
            int methodStart = methodMatcher.start();
            int methodEnd = findMethodEnd(content, methodStart);
            String methodContent = content.substring(methodStart, methodEnd);

            int complexity = calculateCyclomaticComplexity(methodContent);
            totalMethods++;
            totalComplexity += complexity;

            if (complexity > maxMethodComplexity) {
                maxMethodComplexity = complexity;
                mostComplexMethod = currentClass + "." + methodName;
            }

            classComplexities.put(currentClass, classComplexities.getOrDefault(currentClass, 0) + complexity);
        }
    }

    private int findMethodEnd(String content, int startPos) {
        int braceCount = 0;
        boolean inMethod = false;

        for (int i = startPos; i < content.length(); i++) {
            char c = content.charAt(i);
            if (c == '{') {
                braceCount++;
                inMethod = true;
            } else if (c == '}') {
                braceCount--;
                if (inMethod && braceCount == 0) {
                    return i + 1;
                }
            }
        }
        return content.length();
    }

    private int calculateCyclomaticComplexity(String methodContent) {
        Matcher matcher = CYCLOMATIC_PATTERN.matcher(methodContent);
        int complexity = 1; // Base complexity
        while (matcher.find()) {
            complexity++;
        }
        return complexity;
    }

    public void printResults() {
        System.out.println("Java Complexity Analysis Results:");
        System.out.println("Total Classes: " + totalClasses);
        System.out.println("Total Methods: " + totalMethods);
        System.out.println("Total Cyclomatic Complexity: " + totalComplexity);
        System.out.println("Average Method Complexity: " + (totalMethods > 0 ? (double) totalComplexity / totalMethods : 0));
        System.out.println("Most Complex Method: " + mostComplexMethod + " (Complexity: " + maxMethodComplexity + ")");

        System.out.println("\nTop 10 Most Complex Classes:");
        classComplexities.entrySet().stream()
            .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
            .limit(10)
            .forEach(entry -> System.out.println(entry.getKey() + ": " + entry.getValue()));
    }

    public Map<String, Object> getResults() {
        Map<String, Object> results = new HashMap<>();
        results.put("totalClasses", totalClasses);
        results.put("totalMethods", totalMethods);
        results.put("totalComplexity", totalComplexity);
        results.put("averageMethodComplexity", totalMethods > 0 ? (double) totalComplexity / totalMethods : 0);
        results.put("maxMethodComplexity", maxMethodComplexity);
        results.put("mostComplexMethod", mostComplexMethod);
        results.put("classComplexities", classComplexities);
        return results;
    }

    public static void main(String[] args) {
        try {
            if (args.length != 1) {
                System.err.println("Usage: JavaComplexityAnalyzer <project-path>");
                System.exit(1);
            }

            JavaComplexityAnalyzer analyzer = new JavaComplexityAnalyzer();
            analyzer.analyzeDirectory(Paths.get(args[0]));
            analyzer.printResults();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
EOF

    # Compile and run the analyzer
    javac "$OUTPUT_DIR/JavaComplexityAnalyzer.java"
    if [[ $? -eq 0 ]]; then
        log_info "Running Java complexity analysis..."
        cd "$OUTPUT_DIR"
        java JavaComplexityAnalyzer "$PROJECT_PATH" > "$OUTPUT_DIR/raw-data/java-complexity.txt"

        # Convert to JSON for easier processing
        python3 << EOF > "$OUTPUT_DIR/metrics/java-complexity.json"
import json
import re

with open('$OUTPUT_DIR/raw-data/java-complexity.txt', 'r') as f:
    content = f.read()

results = {}
lines = content.split('\n')
for line in lines:
    if ': ' in line:
        key, value = line.split(': ', 1)
        key = key.strip().lower().replace(' ', '_')
        if value.isdigit():
            results[key] = int(value)
        else:
            try:
                results[key] = float(value)
            except ValueError:
                results[key] = value

print(json.dumps(results, indent=2))
EOF
        log_success "Java complexity analysis completed"
    else
        log_error "Failed to compile Java complexity analyzer"
    fi
}

# Analyze JavaScript/TypeScript complexity
analyze_js_complexity() {
    log_info "Analyzing JavaScript/TypeScript complexity..."

    if ! command -v node &> /dev/null; then
        log_warning "Node.js not found. Skipping JavaScript-specific analysis."
        return
    fi

    # Create JavaScript complexity analyzer
    cat > "$OUTPUT_DIR/js-complexity-analyzer.js" << 'EOF'
const fs = require('fs');
const path = require('path');

function analyzeJavaScriptComplexity(projectPath) {
    const results = {
        totalFiles: 0,
        totalLines: 0,
        totalFunctions: 0,
        totalComplexity: 0,
        fileComplexities: []
    };

    function walkDirectory(dir, callback) {
        const files = fs.readdirSync(dir);
        for (const file of files) {
            const filePath = path.join(dir, file);
            const stat = fs.statSync(filePath);

            if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules' && file !== 'build' && file !== 'dist') {
                walkDirectory(filePath, callback);
            } else if (stat.isFile() && (file.endsWith('.js') || file.endsWith('.jsx') || file.endsWith('.ts') || file.endsWith('.tsx'))) {
                callback(filePath);
            }
        }
    }

    function calculateComplexity(content) {
        const complexityPatterns = [
            /\bif\b/g,
            /\bfor\b/g,
            /\bwhile\b/g,
            /\bcase\b/g,
            /\bcatch\b/g,
            /\&\&/g,
            /\|\|/g
        ];

        let complexity = 1; // Base complexity
        for (const pattern of complexityPatterns) {
            const matches = content.match(pattern);
            if (matches) {
                complexity += matches.length;
            }
        }
        return complexity;
    }

    function analyzeFile(filePath) {
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            const lines = content.split('\n').length;
            const functionMatches = content.match(/\bfunction\b|\b=>\b/g) || [];
            const functions = functionMatches.length;
            const complexity = calculateComplexity(content);

            const fileName = path.basename(filePath);

            results.totalFiles++;
            results.totalLines += lines;
            results.totalFunctions += functions;
            results.totalComplexity += complexity;

            results.fileComplexities.push({
                file: fileName,
                lines: lines,
                functions: functions,
                complexity: complexity
            });
        } catch (error) {
            console.error(`Error analyzing file ${filePath}:`, error.message);
        }
    }

    walkDirectory(projectPath, analyzeFile);

    // Sort files by complexity
    results.fileComplexities.sort((a, b) => b.complexity - a.complexity);

    return results;
}

if (require.main === module) {
    const projectPath = process.argv[2];
    if (!projectPath) {
        console.error('Usage: node js-complexity-analyzer.js <project-path>');
        process.exit(1);
    }

    const results = analyzeJavaScriptComplexity(projectPath);
    console.log(JSON.stringify(results, null, 2));
}
EOF

    # Run the analysis
    cd "$OUTPUT_DIR"
    node js-complexity-analyzer.js "$PROJECT_PATH" > "$OUTPUT_DIR/metrics/js-complexity.json"
    log_success "JavaScript/TypeScript complexity analysis completed"
}

# Analyze Python complexity
analyze_python_complexity() {
    log_info "Analyzing Python code complexity..."

    cat > "$OUTPUT_DIR/python-complexity-analyzer.py" << 'EOF'
import os
import ast
import json
from collections import defaultdict

class PythonComplexityAnalyzer:
    def __init__(self):
        self.results = {
            'total_files': 0,
            'total_lines': 0,
            'total_functions': 0,
            'total_classes': 0,
            'total_complexity': 0,
            'file_complexities': []
        }

    def analyze_directory(self, project_path):
        for root, dirs, files in os.walk(project_path):
            # Skip hidden directories and common build directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['__pycache__', 'node_modules', 'venv', 'env']]

            for file in files:
                if file.endswith('.py'):
                    file_path = os.path.join(root, file)
                    self.analyze_file(file_path)

    def analyze_file(self, file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            tree = ast.parse(content)
            lines = len(content.split('\n'))
            functions = self.count_functions(tree)
            classes = self.count_classes(tree)
            complexity = self.calculate_complexity(tree)

            self.results['total_files'] += 1
            self.results['total_lines'] += lines
            self.results['total_functions'] += functions
            self.results['total_classes'] += classes
            self.results['total_complexity'] += complexity

            self.results['file_complexities'].append({
                'file': os.path.basename(file_path),
                'lines': lines,
                'functions': functions,
                'classes': classes,
                'complexity': complexity
            })
        except Exception as e:
            print(f"Error analyzing file {file_path}: {e}")

    def count_functions(self, tree):
        count = 0
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                count += 1
        return count

    def count_classes(self, tree):
        count = 0
        for node in ast.walk(tree):
            if isinstance(node, ast.ClassDef):
                count += 1
        return count

    def calculate_complexity(self, tree):
        complexity = 1  # Base complexity
        for node in ast.walk(tree):
            if isinstance(node, (ast.If, ast.For, ast.While, ast.With, ast.Try, ast.ExceptHandler)):
                complexity += 1
            elif isinstance(node, ast.BoolOp):
                complexity += len(node.values) - 1
        return complexity

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 2:
        print('Usage: python python-complexity-analyzer.py <project-path>')
        sys.exit(1)

    analyzer = PythonComplexityAnalyzer()
    analyzer.analyze_directory(sys.argv[1])
    print(json.dumps(analyzer.results, indent=2))
EOF

    # Run the analysis
    python3 "$OUTPUT_DIR/python-complexity-analyzer.py" "$PROJECT_PATH" > "$OUTPUT_DIR/metrics/python-complexity.json"
    log_success "Python complexity analysis completed"
}

# Analyze code duplication
analyze_duplication() {
    log_info "Analyzing code duplication..."

    # Use PMD CPD for Java if available
    if command -v pmd &> /dev/null && [[ "$PROJECT_TYPE" == "java" ]]; then
        log_info "Running PMD Copy/Paste Detector for Java..."
        pmd cpd --minimum-tokens 50 --files "$PROJECT_PATH" --format csv --output-file "$OUTPUT_DIR/raw-data/java-duplication.csv"
    fi

    # Create simple duplication detector
    cat > "$OUTPUT_DIR/duplication-detector.py" << 'EOF'
import os
import re
import json
from collections import defaultdict

def find_duplicate_blocks(project_path, min_block_size=5):
    blocks = defaultdict(list)

    for root, dirs, files in os.walk(project_path):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', 'target', 'build', '__pycache__']]

        for file in files:
            file_path = os.path.join(root, file)
            if file.endswith(('.java', '.py', '.js', '.jsx', '.ts', '.tsx')):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Split into lines and normalize
                    lines = [line.strip() for line in content.split('\n') if line.strip()]

                    # Find blocks of code
                    for i in range(len(lines) - min_block_size + 1):
                        block = '\n'.join(lines[i:i + min_block_size])
                        blocks[block].append({
                            'file': os.path.relpath(file_path, project_path),
                            'start_line': i + 1
                        })
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

    # Find duplicates
    duplicates = {block: locations for block, locations in blocks.items() if len(locations) > 1}

    return {
        'total_blocks_analyzed': len(blocks),
        'duplicate_blocks_found': len(duplicates),
        'duplicates': {block: locations for block, locations in list(duplicates.items())[:10]}  # Top 10 duplicates
    }

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 2:
        print('Usage: python duplication-detector.py <project-path>')
        sys.exit(1)

    results = find_duplicate_blocks(sys.argv[1])
    print(json.dumps(results, indent=2))
EOF

    python3 "$OUTPUT_DIR/duplication-detector.py" "$PROJECT_PATH" > "$OUTPUT_DIR/metrics/duplication-analysis.json"
    log_success "Code duplication analysis completed"
}

# Calculate technical debt metrics
calculate_technical_debt() {
    log_info "Calculating technical debt metrics..."

    # Create technical debt analyzer
    cat > "$OUTPUT_DIR/technical-debt-analyzer.py" << 'EOF'
import os
import re
import json
from collections import defaultdict

def analyze_technical_debt(project_path):
    debt_metrics = {
        'code_smells': defaultdict(int),
        'code_quality': {},
        'maintenance_index': 0
    }

    total_files = 0
    total_lines = 0
    complex_files = 0
    large_files = 0

    for root, dirs, files in os.walk(project_path):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', 'target', 'build', '__pycache__']]

        for file in files:
            file_path = os.path.join(root, file)
            if file.endswith(('.java', '.py', '.js', '.jsx', '.ts', '.tsx')):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    lines = content.split('\n')
                    total_files += 1
                    total_lines += len(lines)

                    # Analyze code smells
                    analyze_code_smells(content, file, debt_metrics['code_smells'])

                    # File size analysis
                    if len(lines) > 500:
                        large_files += 1
                        debt_metrics['code_smells']['large_file'] += 1

                    # Complexity analysis (simplified)
                    complexity = calculate_complexity(content)
                    if complexity > 10:
                        complex_files += 1
                        debt_metrics['code_smells']['high_complexity'] += 1

                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

    # Calculate maintenance index (simplified formula)
    if total_files > 0:
        debt_metrics['code_quality'] = {
            'total_files': total_files,
            'total_lines': total_lines,
            'average_lines_per_file': total_lines / total_files,
            'complex_files_ratio': complex_files / total_files,
            'large_files_ratio': large_files / total_files
        }

        # Simplified maintenance index (0-100, higher is better)
        debt_metrics['maintenance_index'] = max(0, 100 - (debt_metrics['code_quality']['complex_files_ratio'] * 50) - (debt_metrics['code_quality']['large_files_ratio'] * 30))

    return debt_metrics

def analyze_code_smells(content, filename, code_smells):
    lines = content.split('\n')

    # Long methods
    in_method = False
    method_lines = 0
    for line in lines:
        if re.search(r'\b(function|def|class|public|private|protected)\s+\w+', line):
            if in_method and method_lines > 50:
                code_smells['long_method'] += 1
            method_lines = 0
            in_method = True
        elif in_method:
            method_lines += 1

    # TODO comments
    for line in lines:
        if 'TODO' in line or 'FIXME' in line or 'HACK' in line:
            code_smells['todo_comments'] += 1

    # Dead code indicators
    if re.search(r'print\(|console\.log\(|System\.out\.print\(', content):
        code_smells['debug_code'] += 1

    # Magic numbers
    magic_numbers = re.findall(r'\b\d{2,}\b', content)
    if len(magic_numbers) > 5:
        code_smells['magic_numbers'] += 1

    # Deep nesting
    max_nesting = 0
    current_nesting = 0
    for line in lines:
        stripped = line.strip()
        if stripped.endswith('{') or stripped.endswith(':'):
            current_nesting += 1
            max_nesting = max(max_nesting, current_nesting)
        elif stripped in ['}', 'pass', 'break;']:
            current_nesting = max(0, current_nesting - 1)

    if max_nesting > 4:
        code_smells['deep_nesting'] += 1

def calculate_complexity(content):
    # Simplified complexity calculation
    complexity_patterns = [
        r'\bif\b', r'\bfor\b', r'\bwhile\b', r'\bcase\b', r'\bcatch\b',
        r'\&\&', r'\|\|', r'\?:'
    ]

    complexity = 1  # Base complexity
    for pattern in complexity_patterns:
        complexity += len(re.findall(pattern, content))

    return complexity

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 2:
        print('Usage: python technical-debt-analyzer.py <project-path>')
        sys.exit(1)

    results = analyze_technical_debt(sys.argv[1])
    print(json.dumps(results, indent=2))
EOF

    python3 "$OUTPUT_DIR/technical-debt-analyzer.py" "$PROJECT_PATH" > "$OUTPUT_DIR/metrics/technical-debt.json"
    log_success "Technical debt analysis completed"
}

# Generate comprehensive report
generate_report() {
    log_info "Generating comprehensive metrics report..."

    cat > "$OUTPUT_DIR/reports/code-metrics-report.md" << EOF
# Code Metrics Analysis Report

Generated on: $(date)
Project Path: $PROJECT_PATH
Project Type: $PROJECT_TYPE

## Executive Summary

This report provides comprehensive code quality metrics to support migration planning and technical debt assessment.

## Lines of Code Analysis

$(if [[ -f "$OUTPUT_DIR/raw-data/loc-breakdown.csv" ]]; then
    echo "### Language Breakdown"
    echo '```'
    cat "$OUTPUT_DIR/raw-data/loc-breakdown.csv" | column -t -s ','
    echo '```'
fi)

## Complexity Analysis

EOF

    # Add language-specific complexity results
    if [[ -f "$OUTPUT_DIR/metrics/java-complexity.json" ]]; then
        echo "### Java Complexity Metrics" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        cat "$OUTPUT_DIR/metrics/java-complexity.json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
    fi

    if [[ -f "$OUTPUT_DIR/metrics/js-complexity.json" ]]; then
        echo "### JavaScript/TypeScript Complexity Metrics" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        cat "$OUTPUT_DIR/metrics/js-complexity.json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
    fi

    if [[ -f "$OUTPUT_DIR/metrics/python-complexity.json" ]]; then
        echo "### Python Complexity Metrics" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/metrics/python-complexity.json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
    fi

    # Add technical debt analysis
    if [[ -f "$OUTPUT_DIR/metrics/technical-debt.json" ]]; then
        echo "### Technical Debt Analysis" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        cat "$OUTPUT_DIR/metrics/technical-debt.json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
    fi

    # Add duplication analysis
    if [[ -f "$OUTPUT_DIR/metrics/duplication-analysis.json" ]]; then
        echo "### Code Duplication Analysis" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        cat "$OUTPUT_DIR/metrics/duplication-analysis.json" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "\`\`\`" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
        echo "" >> "$OUTPUT_DIR/reports/code-metrics-report.md"
    fi

    cat >> "$OUTPUT_DIR/reports/code-metrics-report.md" << 'EOF'
## Migration Recommendations

### Based on Complexity Analysis
1. **High Complexity Areas**: Prioritize refactoring before migration
2. **Large Files**: Consider breaking down into smaller components
3. **Complex Functions**: Target for extraction into separate services

### Based on Technical Debt
1. **Code Smells**: Address critical code smells early in migration
2. **Maintenance Index**: Low maintenance index areas may need complete rewrite
3. **Duplication**: Eliminate code duplication to reduce migration scope

### Risk Assessment
- **High Risk**: Files with complexity > 15 or technical debt score > 50
- **Medium Risk**: Files with complexity 10-15 or moderate technical debt
- **Low Risk**: Files with complexity < 10 and low technical debt

## Next Steps
1. Review complexity hotspots in the codebase
2. Plan refactoring activities for high-risk areas
3. Create migration strategy based on complexity analysis
4. Set quality gates for migration process

EOF

    log_success "Code metrics report generated at $OUTPUT_DIR/reports/code-metrics-report.md"
}

# Make scripts executable
make_scripts_executable() {
    chmod +x "$OUTPUT_DIR"/*.py
    chmod +x "$OUTPUT_DIR"/*.sh 2>/dev/null || true
}

# Main execution
main() {
    log_info "Starting code metrics analysis for project: $PROJECT_PATH"
    log_info "Output directory: $OUTPUT_DIR"

    # Create output directory
    create_output_directory

    # Detect project type
    detect_project_type

    # Run analysis
    count_lines_of_code

    case "$PROJECT_TYPE" in
        "java")
            analyze_java_complexity
            ;;
        "javascript")
            analyze_js_complexity
            ;;
        "python")
            analyze_python_complexity
            ;;
        *)
            log_warning "No specific complexity analysis available for project type: $PROJECT_TYPE"
            ;;
    esac

    # Additional analysis
    analyze_duplication
    calculate_technical_debt
    generate_report
    make_scripts_executable

    log_success "Code metrics analysis completed successfully!"
    log_info "Results saved in: $OUTPUT_DIR"
    log_info "View the main report: $OUTPUT_DIR/reports/code-metrics-report.md"
}

# Run main function
main "$@"