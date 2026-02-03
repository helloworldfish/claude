/**
 * Pre-Tool-Use Hook for Legacy Migration Refactoring
 *
 * This hook runs before tool executions to analyze code and prepare refactoring operations.
 * It enhances code analysis capabilities and ensures safe transformations.
 */

const fs = require('fs');
const path = require('path');

class LegacyMigrationPreToolUseHook {
  constructor() {
    this.analysisCache = new Map();
    this.refactoringPlan = new Map();
  }

  async execute(context) {
    const { tool, toolInput } = context;

    // Enhance Read operations with refactoring insights
    if (tool.name === 'Read') {
      return await this.enhanceReadOperation(context);
    }

    // Prepare refactoring analysis for Edit operations
    if (tool.name === 'Edit') {
      return await this.prepareRefactoring(context);
    }

    // Analyze code structure for Glob operations
    if (tool.name === 'Glob') {
      return await this.enhanceGlobOperation(context);
    }

    return context;
  }

  async enhanceReadOperation(context) {
    const { toolInput } = context;
    const filePath = toolInput.file_path;

    // Only enhance Java file reads
    if (!filePath.endsWith('.java')) {
      return context;
    }

    try {
      // Check if we have cached analysis
      if (this.analysisCache.has(filePath)) {
        const analysis = this.analysisCache.get(filePath);
        context.refactoringContext = {
          analysis,
          suggestions: this.generateRefactoringSuggestions(analysis)
        };
        return context;
      }

      // Perform quick code analysis
      const analysis = await this.analyzeJavaFile(filePath);
      this.analysisCache.set(filePath, analysis);

      context.refactoringContext = {
        analysis,
        suggestions: this.generateRefactoringSuggestions(analysis)
      };

    } catch (error) {
      console.warn('Failed to enhance read operation:', error.message);
    }

    return context;
  }

  async prepareRefactoring(context) {
    const { toolInput } = context;
    const filePath = toolInput.file_path;

    if (!filePath.endsWith('.java')) {
      return context;
    }

    try {
      // Analyze current state and planned changes
      const currentAnalysis = this.analysisCache.get(filePath) ||
                             await this.analyzeJavaFile(filePath);

      const plannedChanges = this.analyzePlannedChanges(
        currentAnalysis,
        toolInput.old_string,
        toolInput.new_string
      );

      // Validate refactoring safety
      const validation = this.validateRefactoring(currentAnalysis, plannedChanges);

      context.refactoringPlan = {
        currentAnalysis,
        plannedChanges,
        validation,
        recommendations: this.generateRefactoringRecommendations(plannedChanges)
      };

    } catch (error) {
      console.warn('Failed to prepare refactoring:', error.message);
    }

    return context;
  }

  async enhanceGlobOperation(context) {
    const { toolInput } = context;
    const pattern = toolInput.pattern;

    // Enhance Java file patterns with refactoring context
    if (pattern.includes('*.java') || pattern.includes('**/*.java')) {
      context.javaPatternEnhancement = {
        suggestRefactoring: true,
        analyzeDependencies: true,
        generateMetrics: true
      };
    }

    return context;
  }

  async analyzeJavaFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');

    return {
      filePath,
      complexity: this.calculateComplexity(content),
      patterns: this.detectPatterns(content),
      dependencies: this.extractDependencies(content),
      smells: this.detectCodeSmells(content),
      metrics: this.calculateMetrics(content),
      refactoringOpportunities: this.identifyRefactoringOpportunities(content)
    };
  }

  calculateComplexity(content) {
    // Simplified cyclomatic complexity calculation
    const complexityKeywords = ['if', 'else', 'for', 'while', 'case', 'catch', '&&', '||'];
    let complexity = 1; // Base complexity

    for (const keyword of complexityKeywords) {
      const regex = new RegExp(`\\b${keyword}\\b`, 'g');
      const matches = content.match(regex);
      if (matches) {
        complexity += matches.length;
      }
    }

    return complexity;
  }

  detectPatterns(content) {
    const patterns = {
      singleton: /singleton|getInstance\s*\(/gi.test(content),
      factory: /factory|create\w*\s*\(/gi.test(content),
      strategy: /strategy|.*Strategy/gi.test(content),
      observer: /observer|listener|event/gi.test(content),
      repository: /repository|extends.*Repository/gi.test(content),
      service: /@Service|service/gi.test(content),
      controller: /@Controller|@RestController/gi.test(content)
    };

    return patterns;
  }

  extractDependencies(content) {
    const imports = content.match(/import\s+[\w.]+;/g) || [];
    const springAnnotations = content.match(/@\w+/g) || [];
    const methodCalls = content.match(/\w+\.\w+\(/g) || [];

    return {
      imports: imports.map(imp => imp.replace(/import\s+|;/g, '')),
      springAnnotations,
      methodCalls: [...new Set(methodCalls)]
    };
  }

  detectCodeSmells(content) {
    const smells = [];

    // Long method detection
    const methods = content.match(/(?:public|private|protected)?\s*[\w<>]+\s+\w+\s*\([^)]*\)\s*\{[^}]*\}/gs) || [];
    methods.forEach((method, index) => {
      const lines = method.split('\n').length;
      if (lines > 30) {
        smells.push({
          type: 'Long Method',
          location: `Method ${index + 1}`,
          lines,
          recommendation: 'Extract smaller methods with single responsibilities'
        });
      }
    });

    // Large class detection
    const classLines = content.split('\n').length;
    if (classLines > 300) {
      smells.push({
        type: 'Large Class',
        lines: classLines,
        recommendation: 'Consider splitting into multiple classes with single responsibilities'
      });
    }

    // Magic numbers
    const numbers = content.match(/\b\d{2,}\b/g) || [];
    if (numbers.length > 0) {
      smells.push({
        type: 'Magic Numbers',
        count: numbers.length,
        examples: numbers.slice(0, 3),
        recommendation: 'Extract magic numbers into named constants'
      });
    }

    return smells;
  }

  calculateMetrics(content) {
    const lines = content.split('\n');
    const nonEmptyLines = lines.filter(line => line.trim().length > 0);
    const commentLines = lines.filter(line => line.trim().startsWith('//') || line.trim().startsWith('*'));

    return {
      totalLines: lines.length,
      codeLines: nonEmptyLines.length - commentLines.length,
      commentLines: commentLines.length,
      commentRatio: commentLines.length / nonEmptyLines.length,
      complexity: this.calculateComplexity(content),
      maintainabilityIndex: Math.max(0, 171 - 5.2 * Math.log(this.calculateComplexity(content)) - 0.23 * this.calculateComplexity(content) - 16.2 * Math.log(lines.length))
    };
  }

  identifyRefactoringOpportunities(content) {
    const opportunities = [];

    // Extract method opportunities
    if (this.calculateComplexity(content) > 10) {
      opportunities.push({
        type: 'Extract Method',
        priority: 'High',
        description: 'Complex method that could benefit from extraction',
        estimatedEffort: '2-4 hours'
      });
    }

    // Extract class opportunities
    if (content.includes('class') && content.split('class').length > 3) {
      opportunities.push({
        type: 'Extract Class',
        priority: 'Medium',
        description: 'Multiple responsibilities that could be separated',
        estimatedEffort: '4-8 hours'
      });
    }

    // Pattern opportunities
    if (content.includes('switch') && content.match(/case\s+\w+:/g)?.length > 3) {
      opportunities.push({
        type: 'Apply Strategy Pattern',
        priority: 'High',
        description: 'Switch statement with multiple cases could be replaced with Strategy pattern',
        estimatedEffort: '6-10 hours'
      });
    }

    return opportunities;
  }

  generateRefactoringSuggestions(analysis) {
    const suggestions = [];

    if (analysis.complexity > 15) {
      suggestions.push({
        type: 'Complexity Reduction',
        message: `High complexity detected (${analysis.complexity}). Consider extracting methods or applying design patterns.`,
        action: 'extract-method'
      });
    }

    if (analysis.metrics.maintainabilityIndex < 60) {
      suggestions.push({
        type: 'Maintainability Improvement',
        message: `Low maintainability index (${analysis.metrics.maintainabilityIndex.toFixed(1)}). Refactoring recommended.`,
        action: 'comprehensive-refactor'
      });
    }

    if (analysis.codeSmells.length > 0) {
      suggestions.push({
        type: 'Code Smell Resolution',
        message: `Found ${analysis.codeSmells.length} code smells that should be addressed.`,
        action: 'fix-code-smells',
        smells: analysis.codeSmells
      });
    }

    return suggestions;
  }

  analyzePlannedChanges(analysis, oldString, newString) {
    return {
      type: this.classifyChange(oldString, newString),
      impact: this.assessImpact(analysis, oldString, newString),
      scope: this.determineScope(oldString, newString),
      risk: this.assessRisk(analysis, oldString, newString)
    };
  }

  classifyChange(oldString, newString) {
    if (oldString.length === 0) return 'addition';
    if (newString.length === 0) return 'deletion';

    // Check if it's a method signature change
    if (oldString.includes('public') && newString.includes('public')) return 'method-modification';

    // Check if it's an import change
    if (oldString.includes('import') || newString.includes('import')) return 'dependency-change';

    return 'modification';
  }

  assessImpact(analysis, oldString, newString) {
    let impact = 'low';

    if (oldString.includes('public class')) impact = 'high';
    else if (oldString.includes('public')) impact = 'medium';
    else if (oldString.length > 100) impact = 'medium';

    return impact;
  }

  determineScope(oldString, newString) {
    if (oldString.includes('class') || newString.includes('class')) return 'class-level';
    if (oldString.includes('public') || newString.includes('public')) return 'method-level';
    return 'local';
  }

  assessRisk(analysis, oldString, newString) {
    let risk = 'low';

    if (this.classifyChange(oldString, newString) === 'deletion') risk = 'high';
    else if (this.assessImpact(analysis, oldString, newString) === 'high') risk = 'medium';

    return risk;
  }

  validateRefactoring(analysis, plannedChanges) {
    const issues = [];

    if (plannedChanges.type === 'deletion' && plannedChanges.impact === 'high') {
      issues.push({
        severity: 'warning',
        message: 'Deleting high-impact code. Consider backward compatibility.',
        suggestion: 'Use @Deprecated annotation first'
      });
    }

    if (plannedChanges.risk === 'high' && analysis.complexity > 20) {
      issues.push({
        severity: 'error',
        message: 'High-risk change in complex code. Refactor in smaller steps.',
        suggestion: 'Break down into multiple smaller changes'
      });
    }

    return {
      isValid: issues.filter(i => i.severity === 'error').length === 0,
      issues
    };
  }

  generateRefactoringRecommendations(plannedChanges) {
    const recommendations = [];

    if (plannedChanges.impact === 'high') {
      recommendations.push({
        action: 'Create backup before refactoring',
        reason: 'High-impact changes may affect multiple components'
      });
    }

    if (plannedChanges.risk === 'high') {
      recommendations.push({
        action: 'Run comprehensive tests after refactoring',
        reason: 'High-risk changes may introduce bugs'
      });
    }

    if (plannedChanges.scope === 'class-level') {
      recommendations.push({
        action: 'Review and update related documentation',
        reason: 'Class-level changes affect API contracts'
      });
    }

    return recommendations;
  }
}

// Export the hook
module.exports = {
  execute: async (context) => {
    const hook = new LegacyMigrationPreToolUseHook();
    return await hook.execute(context);
  }
};