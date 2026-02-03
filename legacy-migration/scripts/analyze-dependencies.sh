#!/bin/bash

# Dependency Analysis Script for Legacy Migration
# This script analyzes dependencies in a monolithic codebase to support migration planning

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/dependency-analysis}"
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
    mkdir -p "$OUTPUT_DIR"/{raw-data,reports,graphs}
}

# Detect project type and set up analysis tools
detect_project_type() {
    log_info "Detecting project type..."

    if [[ -f "$PROJECT_PATH/pom.xml" ]]; then
        PROJECT_TYPE="java-maven"
        log_success "Detected Java Maven project"
    elif [[ -f "$PROJECT_PATH/build.gradle" ]]; then
        PROJECT_TYPE="java-gradle"
        log_success "Detected Java Gradle project"
    elif [[ -f "$PROJECT_PATH/package.json" ]]; then
        PROJECT_TYPE="nodejs"
        log_success "Detected Node.js project"
    elif [[ -f "$PROJECT_PATH/requirements.txt" || -f "$PROJECT_PATH/setup.py" ]]; then
        PROJECT_TYPE="python"
        log_success "Detected Python project"
    elif [[ -f "$PROJECT_PATH/Gemfile" ]]; then
        PROJECT_TYPE="ruby"
        log_success "Detected Ruby project"
    else
        PROJECT_TYPE="generic"
        log_warning "Could not detect specific project type, using generic analysis"
    fi
}

# Analyze Java Maven dependencies
analyze_java_maven() {
    log_info "Analyzing Java Maven dependencies..."

    # Check if Maven is available
    if ! command -v mvn &> /dev/null; then
        log_error "Maven not found. Please install Maven to analyze Java projects."
        return 1
    fi

    # Generate dependency tree
    log_info "Generating Maven dependency tree..."
    cd "$PROJECT_PATH"
    mvn dependency:tree -DoutputFile="$OUTPUT_DIR/raw-data/maven-dependencies.txt" -DappendOutput=false

    # Generate dependency analysis
    log_info "Analyzing dependency conflicts and issues..."
    mvn dependency:analyze -DoutputFile="$OUTPUT_DIR/raw-data/maven-analysis.txt"

    # Generate dependency graph
    if command -v jdeps &> /dev/null; then
        log_info "Generating Java dependency graph..."
        find "$PROJECT_PATH" -name "*.class" -type f | head -100 | xargs jdeps -dotoutput "$OUTPUT_DIR/graphs/java-dependencies"
    fi
}

# Analyze Java Gradle dependencies
analyze_java_gradle() {
    log_info "Analyzing Java Gradle dependencies..."

    if ! command -v gradle &> /dev/null && ! command -v ./gradlew &> /dev/null; then
        log_error "Gradle not found. Please install Gradle to analyze Gradle projects."
        return 1
    fi

    cd "$PROJECT_PATH"

    # Try to use gradlew first, then system gradle
    if [[ -f "./gradlew" ]]; then
        GRADLE_CMD="./gradlew"
    else
        GRADLE_CMD="gradle"
    fi

    # Generate dependency tree
    log_info "Generating Gradle dependency tree..."
    $GRADLE_CMD dependencies > "$OUTPUT_DIR/raw-data/gradle-dependencies.txt"

    # Generate dependency report
    log_info "Generating dependency report..."
    $GRADLE dependencyInsight --configuration compile > "$OUTPUT_DIR/raw-data/gradle-insight.txt"
}

# Analyze Node.js dependencies
analyze_nodejs() {
    log_info "Analyzing Node.js dependencies..."

    if ! command -v npm &> /dev/null; then
        log_error "npm not found. Please install npm to analyze Node.js projects."
        return 1
    fi

    cd "$PROJECT_PATH"

    # Generate dependency tree
    log_info "Generating npm dependency tree..."
    npm ls --json > "$OUTPUT_DIR/raw-data/npm-dependencies.json"

    # Generate dependency graph
    if command -v madge &> /dev/null; then
        log_info "Generating module dependency graph..."
        madge --image "$OUTPUT_DIR/graphs/nodejs-dependencies.png" .
        madge --json "$OUTPUT_DIR/raw-data/nodejs-dependencies.json" .
    else
        log_warning "madge not found. Install with 'npm install -g madge' for dependency graphs."
    fi

    # Check for security vulnerabilities
    log_info "Checking for security vulnerabilities..."
    npm audit --json > "$OUTPUT_DIR/raw-data/npm-audit.json" || true
}

# Analyze Python dependencies
analyze_python() {
    log_info "Analyzing Python dependencies..."

    if ! command -v pipdeptree &> /dev/null; then
        log_warning "pipdeptree not found. Install with 'pip install pipdeptree' for detailed dependency analysis."
    else
        log_info "Generating Python dependency tree..."
        pipdeptree --json > "$OUTPUT_DIR/raw-data/python-dependencies.json"
    fi

    # Analyze imports in Python files
    log_info "Analyzing Python imports..."
    find "$PROJECT_PATH" -name "*.py" -type f | while read -r file; do
        echo "=== $file ===" >> "$OUTPUT_DIR/raw-data/python-imports.txt"
        grep -E "^import|^from" "$file" >> "$OUTPUT_DIR/raw-data/python-imports.txt" || true
        echo "" >> "$OUTPUT_DIR/raw-data/python-imports.txt"
    done
}

# Generic file-based dependency analysis
analyze_generic() {
    log_info "Performing generic dependency analysis..."

    # Analyze import patterns in common file types
    declare -A file_types=(
        ["java":"import"]
        ["py":"import|from"]
        ["js":"import|require|export"]
        ["ts":"import|require|export"]
        ["cpp":"#include"]
        ["c":"#include"]
        ["h":"#include"]
    )

    for ext in "${!file_types[@]}"; do
        pattern="${file_types[$ext]}"
        log_info "Analyzing $ext files for dependencies..."

        find "$PROJECT_PATH" -name "*.$ext" -type f | while read -r file; do
            echo "=== $file ===" >> "$OUTPUT_DIR/raw-data/generic-dependencies.txt"
            grep -E "$pattern" "$file" >> "$OUTPUT_DIR/raw-data/generic-dependencies.txt" || true
            echo "" >> "$OUTPUT_DIR/raw-data/generic-dependencies.txt"
        done
    done
}

# Analyze package dependencies and coupling
analyze_coupling() {
    log_info "Analyzing package coupling and structure..."

    # Create coupling analysis script
    cat > "$OUTPUT_DIR/coupling-analysis.py" << 'EOF'
#!/usr/bin/env python3
import os
import re
import json
from collections import defaultdict, Counter
import argparse

def analyze_project_structure(project_path):
    """Analyze project structure and package dependencies."""
    structure = {
        'packages': defaultdict(set),
        'imports': defaultdict(set),
        'coupling': defaultdict(lambda: defaultdict(int))
    }

    # File patterns for different languages
    patterns = {
        'java': r'import\s+([a-zA-Z_][a-zA-Z0-9_.]*)',
        'py': r'(?:import\s+([a-zA-Z_][a-zA-Z0-9_.]*)|from\s+([a-zA-Z_][a-zA-Z0-9_.]*)\s+import)',
        'js': r'(?:import\s+.*?\s+from\s+["\']([^"\']+)["\']|require\(["\']([^"\']+)["\'])',
        'ts': r'(?:import\s+.*?\s+from\s+["\']([^"\']+)["\']|require\(["\']([^"\']+)["\'])'
    }

    for root, dirs, files in os.walk(project_path):
        # Skip hidden directories and common build directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', 'target', 'build', '__pycache__']]

        package = os.path.relpath(root, project_path)

        for file in files:
            file_path = os.path.join(root, file)
            file_ext = file.split('.')[-1] if '.' in file else ''

            if file_ext in patterns:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()

                    # Find imports
                    matches = re.findall(patterns[file_ext], content)
                    for match in matches:
                        if isinstance(match, tuple):
                            imp = match[0] if match[0] else match[1]
                        else:
                            imp = match

                        if imp and not imp.startswith('.'):
                            structure['imports'][package].add(imp)

                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

    return structure

def calculate_coupling(structure):
    """Calculate coupling metrics between packages."""
    coupling = structure['coupling']

    for package, imports in structure['imports'].items():
        for imp in imports:
            # Map imports to packages (simplified)
            parts = imp.split('.')
            for i in range(len(parts)):
                possible_package = '.'.join(parts[:i+1])
                if possible_package in structure['imports']:
                    coupling[package][possible_package] += 1

    return coupling

def generate_report(structure, output_dir):
    """Generate dependency analysis report."""
    coupling = calculate_coupling(structure)

    # Calculate metrics
    total_packages = len(structure['packages'])
    total_dependencies = sum(len(imports) for imports in structure['imports'].values())

    # Find most coupled packages
    afferent_coupling = Counter()  # Number of dependencies on this package
    efferent_coupling = Counter()  # Number of dependencies from this package

    for pkg, deps in coupling.items():
        efferent_coupling[pkg] = len(deps)
        for dep_pkg, count in deps.items():
            afferent_coupling[dep_pkg] += 1

    # Generate report
    report = {
        'summary': {
            'total_packages': total_packages,
            'total_dependencies': total_dependencies,
            'average_dependencies_per_package': total_dependencies / max(total_packages, 1)
        },
        'most_coupled_packages': afferent_coupling.most_common(10),
        'most_dependent_packages': efferent_coupling.most_common(10),
        'coupling_matrix': dict(coupling)
    }

    with open(os.path.join(output_dir, 'coupling-analysis.json'), 'w') as f:
        json.dump(report, f, indent=2)

    return report

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Analyze project dependencies and coupling')
    parser.add_argument('project_path', help='Path to the project directory')
    parser.add_argument('--output', help='Output directory', default='.')

    args = parser.parse_args()

    structure = analyze_project_structure(args.project_path)
    report = generate_report(structure, args.output)

    print("Coupling analysis completed. Check coupling-analysis.json for results.")
EOF

    # Run coupling analysis
    python3 "$OUTPUT_DIR/coupling-analysis.py" "$PROJECT_PATH" "$OUTPUT_DIR"
}

# Generate dependency visualization
generate_visualizations() {
    log_info "Generating dependency visualizations..."

    # Create DOT file for dependency graph
    cat > "$OUTPUT_DIR/graphs/dependencies.dot" << 'EOF'
digraph Dependencies {
    rankdir=LR;
    node [shape=box, style=filled, fillcolor=lightblue];

EOF

    # Add nodes and edges based on analysis results
    if [[ -f "$OUTPUT_DIR/raw-data/maven-dependencies.txt" ]]; then
        # Process Maven dependencies
        grep -E "^\|.*\|.*\|.*$" "$OUTPUT_DIR/raw-data/maven-dependencies.txt" | while IFS='|' read -r group_id artifact_id version scope; do
            if [[ -n "$artifact_id" && "$artifact_id" != "artifactId" ]]; then
                echo "    \"$artifact_id\" [label=\"$artifact_id\\n$version\"];" >> "$OUTPUT_DIR/graphs/dependencies.dot"
            fi
        done
    fi

    echo "}" >> "$OUTPUT_DIR/graphs/dependencies.dot"

    # Generate PNG if Graphviz is available
    if command -v dot &> /dev/null; then
        log_info "Generating dependency graph PNG..."
        dot -Tpng "$OUTPUT_DIR/graphs/dependencies.dot" -o "$OUTPUT_DIR/graphs/dependencies.png"
        log_success "Dependency graph saved to $OUTPUT_DIR/graphs/dependencies.png"
    else
        log_warning "Graphviz not found. Install Graphviz to generate PNG visualizations."
    fi
}

# Generate comprehensive report
generate_report() {
    log_info "Generating comprehensive dependency report..."

    cat > "$OUTPUT_DIR/reports/dependency-analysis-report.md" << EOF
# Dependency Analysis Report

Generated on: $(date)
Project Path: $PROJECT_PATH
Project Type: $PROJECT_TYPE

## Executive Summary

This report analyzes the dependencies within the legacy system to support migration planning.

### Key Metrics
- Total Dependencies Analyzed: $(find "$PROJECT_PATH" -name "*.jar" -o -name "*.class" -o -name "*.js" -o -name "*.py" -o -name "*.java" | wc -l)
- Analysis Files Generated: $(find "$OUTPUT_DIR" -type f | wc -l)
- Project Type Detected: $PROJECT_TYPE

## Detailed Analysis Results

### Dependency Trees
- Maven Dependencies: \`\`\`$([ -f "$OUTPUT_DIR/raw-data/maven-dependencies.txt" ] && echo "Available" || echo "Not available")\`\`\`
- Gradle Dependencies: \`\`\`$([ -f "$OUTPUT_DIR/raw-data/gradle-dependencies.txt" ] && echo "Available" || echo "Not available")\`\`\`
- NPM Dependencies: \`\`\`$([ -f "$OUTPUT_DIR/raw-data/npm-dependencies.json" ] && echo "Available" || echo "Not available")\`\`\`
- Python Dependencies: \`\`\`$([ -f "$OUTPUT_DIR/raw-data/python-dependencies.json" ] && echo "Available" || echo "Not available")\`\`\`

### Coupling Analysis
EOF

    # Add coupling analysis results if available
    if [[ -f "$OUTPUT_DIR/coupling-analysis.json" ]]; then
        python3 -c "
import json
import sys

with open('$OUTPUT_DIR/coupling-analysis.json', 'r') as f:
    data = json.load(f)

summary = data.get('summary', {})
print(f\"- Total Packages: {summary.get('total_packages', 'N/A')}\")
print(f\"- Total Dependencies: {summary.get('total_dependencies', 'N/A')}\")
print(f\"- Average Dependencies per Package: {summary.get('average_dependencies_per_package', 'N/A'):.2f}\")
" >> "$OUTPUT_DIR/reports/dependency-analysis-report.md"
    fi

    cat >> "$OUTPUT_DIR/reports/dependency-analysis-report.md" << EOF

## Recommendations

### Migration Strategy
Based on the dependency analysis, consider the following:

1. **High-Coupling Areas**: Focus on decoupling highly coupled components first
2. **Independent Modules**: Target modules with fewer dependencies for initial extraction
3. **Shared Dependencies**: Plan for shared service or API layer for common dependencies

### Risk Mitigation
- Create anticorruption layers for complex integrations
- Implement gradual migration to minimize dependency risks
- Monitor for circular dependencies during migration

## Next Steps
1. Review the generated dependency graphs
2. Identify natural service boundaries
3. Plan migration sequence based on dependency analysis
4. Create service decomposition strategy

## Generated Files
EOF

    # List generated files
    find "$OUTPUT_DIR" -type f -name "*.txt" -o -name "*.json" -o -name "*.dot" -o -name "*.png" | while read -r file; do
        relative_path=$(basename "$file")
        file_type=$(file "$file" | cut -d':' -f2)
        echo "- \`$relative_path\`: $file_type" >> "$OUTPUT_DIR/reports/dependency-analysis-report.md"
    done

    log_success "Dependency analysis report generated at $OUTPUT_DIR/reports/dependency-analysis-report.md"
}

# Main execution
main() {
    log_info "Starting dependency analysis for project: $PROJECT_PATH"
    log_info "Output directory: $OUTPUT_DIR"

    # Create output directory
    create_output_directory

    # Detect project type
    detect_project_type

    # Run analysis based on project type
    case "$PROJECT_TYPE" in
        "java-maven")
            analyze_java_maven
            ;;
        "java-gradle")
            analyze_java_gradle
            ;;
        "nodejs")
            analyze_nodejs
            ;;
        "python")
            analyze_python
            ;;
        *)
            analyze_generic
            ;;
    esac

    # Additional analysis
    analyze_coupling
    generate_visualizations
    generate_report

    log_success "Dependency analysis completed successfully!"
    log_info "Results saved in: $OUTPUT_DIR"
    log_info "View the main report: $OUTPUT_DIR/reports/dependency-analysis-report.md"
}

# Run main function
main "$@"