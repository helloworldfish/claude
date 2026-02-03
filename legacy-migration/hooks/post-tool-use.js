/**
 * Post-Tool-Use Hook for Legacy Migration Refactoring
 *
 * This hook runs after tool executions to validate refactoring results,
 * generate quality metrics, and provide automated testing recommendations.
 */

const fs = require('fs');
const path = require('path');

class LegacyMigrationPostToolUseHook {
  constructor() {
    this.refactoringHistory = new Map();
    this.testResults = new Map();
    this.qualityMetrics = new Map();
  }

  async execute(context) {
    const { tool, toolInput, result } = context;

    // Validate Edit operations
    if (tool.name === 'Edit' && result.success) {
      return await this.validateRefactoringResult(context);
    }

    // Analyze Write operations
    if (tool.name === 'Write' && result.success) {
      return await this.analyzeNewCode(context);
    }

    // Generate recommendations after successful operations
    if (result.success) {
      return await this.generateRecommendations(context);
    }

    return context;
  }

  async validateRefactoringResult(context) {
    const { toolInput, result } = context;
    const filePath = toolInput.file_path;

    try {
      // Read the modified file
      const modifiedContent = fs.readFileSync(filePath, 'utf8');

      // Perform post-refactoring analysis
      const analysis = await this.analyzeModifiedCode(filePath, modifiedContent);

      // Compare with pre-refactoring state if available
      const comparison = this.compareWithOriginal(filePath, analysis);

      // Validate code quality
      const validation = this.validateCodeQuality(modifiedContent);

      // Generate test recommendations
      const testRecommendations = this.generateTestRecommendations(modifiedContent, toolInput);

      // Check for compilation issues
      const compilationCheck = await this.checkCompilation(filePath);

      context.refactoringValidation = {
        analysis,
        comparison,
        validation,
        testRecommendations,
        compilationCheck,
        success: validation.isValid && compilationCheck.compiles
      };

      // Store in history
      this.refactoringHistory.set(filePath, {
        timestamp: new Date(),
        changes: toolInput,
        analysis,
        validation
      });

    } catch (error) {
      console.warn('Failed to validate refactoring result:', error.message);
      context.refactoringValidation = {
        success: false,
        error: error.message
      };
    }

    return context;
  }

  async analyzeNewCode(context) {
    const { toolInput, result } = context;
    const filePath = toolInput.file_path;

    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const analysis = await this.analyzeModifiedCode(filePath, content);

      context.newCodeAnalysis = {
        analysis,
        qualityScore: this.calculateQualityScore(analysis),
        suggestions: this.generateImprovementSuggestions(analysis),
        testCoverage: this.estimateRequiredTestCoverage(content)
      };

    } catch (error) {
      console.warn('Failed to analyze new code:', error.message);
    }

    return context;
  }

  async generateRecommendations(context) {
    const { tool, result } = context;

    const recommendations = [];

    // Add tool-specific recommendations
    if (tool.name === 'Edit') {
      recommendations.push(...this.getEditRecommendations(context));
    } else if (tool.name === 'Write') {
      recommendations.push(...this.getWriteRecommendations(context));
    }

    // Add general refactoring recommendations
    recommendations.push(...this.getGeneralRecommendations(context));

    context.recommendations = recommendations;
    return context;
  }

  async analyzeModifiedCode(filePath, content) {
    return {
      filePath,
      complexity: this.calculateComplexity(content),
      patterns: this.detectDesignPatterns(content),
      smells: this.detectCodeSmells(content),
      metrics: this.calculateQualityMetrics(content),
      testability: this.assessTestability(content),
      maintainability: this.assessMaintainability(content),
      dependencies: this.analyzeDependencies(content),
      security: this.performSecurityAnalysis(content)
    };
  }

  calculateComplexity(content) {
    const complexityIndicators = [
      /\bif\b/g, /\belse\b/g, /\bfor\b/g, /\bwhile\b/g,
      /\bcase\b/g, /\bcatch\b/g, /\?/g, /\&\&/g, /\|\|/g
    ];

    let complexity = 1; // Base complexity

    for (const indicator of complexityIndicators) {
      const matches = content.match(indicator);
      if (matches) {
        complexity += matches.length;
      }
    }

    return {
      cyclomatic: complexity,
      cognitive: this.calculateCognitiveComplexity(content),
      level: this.getComplexityLevel(complexity)
    };
  }

  calculateCognitiveComplexity(content) {
    // Simplified cognitive complexity calculation
    let complexity = 0;
    const nesting = { if: 0, for: 0, while: 0, catch: 0 };

    const lines = content.split('\n');
    lines.forEach(line => {
      if (line.trim().startsWith('if ')) complexity += 1 + nesting.if++;
      if (line.trim().startsWith('else')) complexity += 1;
      if (line.trim().startsWith('for ')) complexity += 1 + nesting.for++;
      if (line.trim().startsWith('while ')) complexity += 1 + nesting.while++;
      if (line.trim().startsWith('catch')) complexity += 1 + nesting.catch++;
      if (line.trim() === '}') {
        Object.keys(nesting).forEach(key => {
          if (nesting[key] > 0) nesting[key]--;
        });
      }
    });

    return complexity;
  }

  getComplexityLevel(complexity) {
    if (complexity <= 5) return 'Simple';
    if (complexity <= 10) return 'Moderate';
    if (complexity <= 20) return 'Complex';
    return 'Very Complex';
  }

  detectDesignPatterns(content) {
    const patterns = {
      singleton: {
        detected: /private static.*instance|getInstance\s*\(/gi.test(content),
        confidence: 0.8
      },
      factory: {
        detected: /Factory|create\w*\s*\(/gi.test(content),
        confidence: 0.7
      },
      strategy: {
        detected: /Strategy|interface.*Strategy/gi.test(content),
        confidence: 0.8
      },
      observer: {
        detected: /Observer|Listener|@EventListener/gi.test(content),
        confidence: 0.7
      },
      repository: {
        detected: /@Repository|extends.*Repository/gi.test(content),
        confidence: 0.9
      },
      service: {
        detected: /@Service/gi.test(content),
        confidence: 0.9
      },
      controller: {
        detected: /@Controller|@RestController/gi.test(content),
        confidence: 0.9
      }
    };

    return Object.entries(patterns)
      .filter(([_, pattern]) => pattern.detected)
      .map(([name, pattern]) => ({ name, confidence: pattern.confidence }));
  }

  detectCodeSmells(content) {
    const smells = [];

    // Long method detection
    const methods = content.match(/(?:public|private|protected)?.*?\w+\s*\([^)]*\)\s*\{[^}]*\}/gs) || [];
    methods.forEach((method, index) => {
      const lines = method.split('\n').length;
      if (lines > 30) {
        smells.push({
          type: 'Long Method',
          severity: lines > 50 ? 'high' : 'medium',
          location: `Method ${index + 1}`,
          lines,
          suggestion: 'Extract smaller methods with single responsibilities'
        });
      }
    });

    // Large class detection
    const classLines = content.split('\n').length;
    if (classLines > 300) {
      smells.push({
        type: 'Large Class',
        severity: classLines > 500 ? 'high' : 'medium',
        lines: classLines,
        suggestion: 'Consider splitting into multiple classes with single responsibilities'
      });
    }

    // Magic numbers
    const numbers = content.match(/\b\d{2,}\b/g) || [];
    if (numbers.length > 2) {
      smells.push({
        type: 'Magic Numbers',
        severity: 'low',
        count: numbers.length,
        examples: numbers.slice(0, 3),
        suggestion: 'Extract magic numbers into named constants'
      });
    }

    // Duplicate code detection
    const duplicateBlocks = this.findDuplicateCode(content);
    if (duplicateBlocks.length > 0) {
      smells.push({
        type: 'Duplicate Code',
        severity: 'medium',
        blocks: duplicateBlocks,
        suggestion: 'Extract common functionality into shared methods'
      });
    }

    return smells;
  }

  findDuplicateCode(content) {
    // Simplified duplicate code detection
    const lines = content.split('\n');
    const duplicates = [];

    for (let i = 0; i < lines.length - 3; i++) {
      const block1 = lines.slice(i, i + 3).join('\n').trim();
      if (block1.length < 20) continue;

      for (let j = i + 3; j < lines.length - 3; j++) {
        const block2 = lines.slice(j, j + 3).join('\n').trim();
        if (block1 === block2) {
          duplicates.push({
            line1: i + 1,
            line2: j + 1,
            block: block1
          });
        }
      }
    }

    return duplicates;
  }

  calculateQualityMetrics(content) {
    const lines = content.split('\n');
    const nonEmptyLines = lines.filter(line => line.trim().length > 0);
    const commentLines = lines.filter(line =>
      line.trim().startsWith('//') ||
      line.trim().startsWith('*') ||
      line.trim().startsWith('/*')
    );

    const complexity = this.calculateComplexity(content);

    return {
      totalLines: lines.length,
      codeLines: nonEmptyLines.length - commentLines.length,
      commentLines: commentLines.length,
      commentRatio: commentLines.length / nonEmptyLines.length,
      complexity: complexity.cyclomatic,
      maintainabilityIndex: this.calculateMaintainabilityIndex(content),
      technicalDebt: this.calculateTechnicalDebt(content, complexity)
    };
  }

  calculateMaintainabilityIndex(content) {
    const lines = content.split('\n').length;
    const complexity = this.calculateComplexity(content).cyclomatic;

    // Simplified maintainability index calculation
    return Math.max(0, 171 - 5.2 * Math.log(complexity) - 0.23 * complexity - 16.2 * Math.log(lines));
  }

  calculateTechnicalDebt(content, complexity) {
    let debt = 0;

    // Complexity debt
    if (complexity.cyclomatic > 10) debt += (complexity.cyclomatic - 10) * 2;
    if (complexity.cognitive > 15) debt += (complexity.cognitive - 15) * 1.5;

    // Code smell debt
    const smells = this.detectCodeSmells(content);
    debt += smells.filter(s => s.severity === 'high').length * 5;
    debt += smells.filter(s => s.severity === 'medium').length * 3;
    debt += smells.filter(s => s.severity === 'low').length * 1;

    return {
      hours: debt,
      score: Math.max(0, 100 - debt * 2),
      priority: debt > 20 ? 'high' : debt > 10 ? 'medium' : 'low'
    };
  }

  assessTestability(content) {
    let score = 100;

    // Dependencies
    if (content.includes('new ') && content.match(/new\s+\w+\(/g)?.length > 3) {
      score -= 20; // Hard to test due to direct instantiation
    }

    // Static methods
    if (content.match(/static\s+\w+/g)?.length > 2) {
      score -= 15; // Static methods are harder to test
    }

    // Private methods
    const privateMethods = (content.match(/private\s+\w+\s+\w+\s*\(/g) || []).length;
    if (privateMethods > 5) {
      score -= 10; // Too many private methods may indicate complex logic
    }

    // External dependencies
    const externalCalls = (content.match(/\w+\.\w+\(/g) || []).length;
    if (externalCalls > 10) {
      score -= 15; // Many external dependencies make testing complex
    }

    return {
      score: Math.max(0, score),
      level: score >= 80 ? 'High' : score >= 60 ? 'Medium' : 'Low',
      issues: this.identifyTestabilityIssues(content)
    };
  }

  identifyTestabilityIssues(content) {
    const issues = [];

    if (content.includes('System.')) {
      issues.push('Direct System calls should be abstracted');
    }

    if (content.includes('new Date()') || content.includes('Calendar.')) {
      issues.push('Date/time usage should be abstracted for testing');
    }

    if (content.includes('Math.random()')) {
      issues.push('Random number generation should be abstracted');
    }

    return issues;
  }

  assessMaintainability(content) {
    const metrics = this.calculateQualityMetrics(content);
    const smells = this.detectCodeSmells(content);
    const complexity = this.calculateComplexity(content);

    let score = 100;

    // Complexity impact
    if (complexity.cyclomatic > 20) score -= 30;
    else if (complexity.cyclomatic > 10) score -= 15;

    // Code smell impact
    score -= smells.filter(s => s.severity === 'high').length * 10;
    score -= smells.filter(s => s.severity === 'medium').length * 5;
    score -= smells.filter(s => s.severity === 'low').length * 2;

    // Comments impact
    if (metrics.commentRatio < 0.1) score -= 10;
    else if (metrics.commentRatio < 0.2) score -= 5;

    return {
      score: Math.max(0, score),
      level: score >= 80 ? 'Excellent' : score >= 60 ? 'Good' : score >= 40 ? 'Fair' : 'Poor',
      recommendations: this.generateMaintainabilityRecommendations(content, score)
    };
  }

  generateMaintainabilityRecommendations(content, score) {
    const recommendations = [];

    if (score < 60) {
      recommendations.push('Consider comprehensive refactoring to improve maintainability');
    }

    const complexity = this.calculateComplexity(content);
    if (complexity.cyclomatic > 10) {
      recommendations.push('Reduce cyclomatic complexity by extracting methods');
    }

    const metrics = this.calculateQualityMetrics(content);
    if (metrics.commentRatio < 0.2) {
      recommendations.push('Add more documentation and comments');
    }

    return recommendations;
  }

  analyzeDependencies(content) {
    const imports = content.match(/import\s+[\w.]+;/g) || [];
    const springAnnotations = content.match(/@\w+/g) || [];
    const methodCalls = content.match(/\w+\.\w+\(/g) || [];

    return {
      externalDependencies: imports.length,
      frameworkDependencies: springAnnotations.length,
      methodCalls: methodCalls.length,
      coupling: this.assessCoupling(imports, methodCalls),
      dependencyGraph: this.buildDependencyGraph(imports, methodCalls)
    };
  }

  assessCoupling(imports, methodCalls) {
    let coupling = 'low';

    if (imports.length > 15) coupling = 'medium';
    if (imports.length > 25) coupling = 'high';
    if (methodCalls.length > 20) coupling = 'high';

    return {
      level: coupling,
      importCount: imports.length,
      methodCallCount: methodCalls.length,
      suggestions: this.generateCouplingSuggestions(imports, methodCalls)
    };
  }

  generateCouplingSuggestions(imports, methodCalls) {
    const suggestions = [];

    if (imports.length > 20) {
      suggestions.push('Consider reducing the number of dependencies');
    }

    const frameworkImports = imports.filter(imp => imp.includes('org.springframework'));
    if (frameworkImports.length > imports.length * 0.5) {
      suggestions.push('High framework coupling - consider abstracting framework dependencies');
    }

    return suggestions;
  }

  buildDependencyGraph(imports, methodCalls) {
    // Simplified dependency graph representation
    const dependencies = [...new Set(methodCalls.map(call => call.split('.')[0]))];

    return {
      nodes: dependencies,
      edges: methodCalls.slice(0, 10) // Limit to first 10 for readability
    };
  }

  performSecurityAnalysis(content) {
    const securityIssues = [];

    // SQL injection
    if (content.includes('" + ') && content.toLowerCase().includes('sql')) {
      securityIssues.push({
        type: 'SQL Injection Risk',
        severity: 'high',
        suggestion: 'Use parameterized queries or prepared statements'
      });
    }

    // Hardcoded credentials
    if (content.includes('password') && (content.includes('= "') || content.includes('= \''))) {
      securityIssues.push({
        type: 'Hardcoded Credentials',
        severity: 'high',
        suggestion: 'Use environment variables or secure configuration'
      });
    }

    // XSS vulnerability
    if (content.includes('innerHTML') || content.includes('document.write')) {
      securityIssues.push({
        type: 'XSS Vulnerability',
        severity: 'medium',
        suggestion: 'Use proper output encoding and sanitization'
      });
    }

    return {
      score: Math.max(0, 100 - securityIssues.length * 25),
      issues: securityIssues
    };
  }

  compareWithOriginal(filePath, analysis) {
    const history = this.refactoringHistory.get(filePath);

    if (!history) {
      return { type: 'new_file', improvements: [] };
    }

    const improvements = [];

    // Complexity comparison
    if (analysis.complexity.cyclomatic < history.analysis.complexity.cyclomatic) {
      improvements.push({
        type: 'Complexity Reduction',
        before: history.analysis.complexity.cyclomatic,
        after: analysis.complexity.cyclomatic,
        improvement: history.analysis.complexity.cyclomatic - analysis.complexity.cyclomatic
      });
    }

    // Code smell comparison
    const beforeSmells = history.analysis.smells.length;
    const afterSmells = analysis.smells.length;
    if (afterSmells < beforeSmells) {
      improvements.push({
        type: 'Code Smell Reduction',
        before: beforeSmells,
        after: afterSmells,
        improvement: beforeSmells - afterSmells
      });
    }

    return {
      type: 'modification',
      improvements,
      overall: improvements.length > 0 ? 'positive' : 'neutral'
    };
  }

  validateCodeQuality(content) {
    const validation = {
      isValid: true,
      errors: [],
      warnings: []
    };

    const complexity = this.calculateComplexity(content);
    const smells = this.detectCodeSmells(content);

    // Check for critical issues
    if (complexity.cyclomatic > 50) {
      validation.errors.push('Extremely high complexity - refactoring required');
      validation.isValid = false;
    }

    if (smells.filter(s => s.severity === 'high').length > 5) {
      validation.errors.push('Too many high-severity code smells');
      validation.isValid = false;
    }

    // Check for warnings
    if (complexity.cyclomatic > 20) {
      validation.warnings.push('High complexity detected');
    }

    if (smells.length > 10) {
      validation.warnings.push('Multiple code smells detected');
    }

    return validation;
  }

  generateTestRecommendations(content, toolInput) {
    const recommendations = [];

    // Analyze the type of change
    if (toolInput.old_string && toolInput.new_string) {
      if (toolInput.old_string.includes('public')) {
        recommendations.push({
          type: 'Unit Test',
          priority: 'high',
          description: 'Create unit tests for modified public method'
        });
      }

      if (toolInput.old_string.includes('@Service') || toolInput.new_string.includes('@Service')) {
        recommendations.push({
          type: 'Integration Test',
          priority: 'medium',
          description: 'Test service integration with dependencies'
        });
      }
    }

    // Analyze content for testing opportunities
    if (content.includes('@Controller') || content.includes('@RestController')) {
      recommendations.push({
        type: 'Controller Test',
        priority: 'high',
        description: 'Add or update controller tests for REST endpoints'
      });
    }

    if (content.includes('@Repository')) {
      recommendations.push({
        type: 'Repository Test',
        priority: 'high',
        description: 'Test data access layer with @DataJpaTest'
      });
    }

    return recommendations;
  }

  async checkCompilation(filePath) {
    // Simplified compilation check - in real implementation, would use Java compiler
    try {
      const content = fs.readFileSync(filePath, 'utf8');

      // Basic syntax checks
      const braceBalance = (content.match(/\{/g) || []).length - (content.match(/\}/g) || []).length;
      const parenBalance = (content.match(/\(/g) || []).length - (content.match(/\)/g) || []).length;

      return {
        compiles: braceBalance === 0 && parenBalance === 0,
        syntaxErrors: braceBalance !== 0 || parenBalance !== 0,
        suggestions: braceBalance !== 0 ? 'Check brace balance' : null
      };
    } catch (error) {
      return {
        compiles: false,
        syntaxErrors: true,
        error: error.message
      };
    }
  }

  calculateQualityScore(analysis) {
    let score = 100;

    // Complexity impact
    score -= Math.max(0, analysis.complexity.cyclomatic - 10) * 2;

    // Code smell impact
    score -= analysis.smells.filter(s => s.severity === 'high').length * 10;
    score -= analysis.smells.filter(s => s.severity === 'medium').length * 5;

    // Testability impact
    score -= Math.max(0, 80 - analysis.testability.score);

    // Security impact
    score -= Math.max(0, 100 - analysis.security.score) / 2;

    return Math.max(0, Math.round(score));
  }

  generateImprovementSuggestions(analysis) {
    const suggestions = [];

    if (analysis.complexity.cyclomatic > 10) {
      suggestions.push({
        type: 'Complexity Reduction',
        description: 'Extract methods to reduce cyclomatic complexity',
        priority: 'high'
      });
    }

    if (analysis.testability.score < 70) {
      suggestions.push({
        type: 'Testability Improvement',
        description: 'Reduce dependencies and abstract external services',
        priority: 'medium'
      });
    }

    if (analysis.maintainability.score < 60) {
      suggestions.push({
        type: 'Maintainability Enhancement',
        description: 'Add documentation and improve code structure',
        priority: 'medium'
      });
    }

    return suggestions;
  }

  estimateRequiredTestCoverage(content) {
    const methods = content.match(/(?:public|private|protected)?.*?\w+\s*\([^)]*\)\s*\{/g) || [];
    const publicMethods = methods.filter(m => m.includes('public')).length;

    return {
      totalMethods: methods.length,
      publicMethods: publicMethods,
      recommendedTests: publicMethods + Math.ceil(methods.length * 0.3),
      estimatedCoverage: Math.min(95, (publicMethods / methods.length) * 100)
    };
  }

  getEditRecommendations(context) {
    const recommendations = [];

    if (context.refactoringValidation && !context.refactoringValidation.success) {
      recommendations.push({
        action: 'Review and fix validation issues',
        reason: 'Refactoring validation failed',
        priority: 'high'
      });
    }

    return recommendations;
  }

  getWriteRecommendations(context) {
    const recommendations = [];

    if (context.newCodeAnalysis && context.newCodeAnalysis.qualityScore < 70) {
      recommendations.push({
        action: 'Improve code quality before commit',
        reason: `Quality score is ${context.newCodeAnalysis.qualityScore}/100`,
        priority: 'medium'
      });
    }

    recommendations.push({
      action: 'Write unit tests for new code',
      reason: 'New code should have comprehensive test coverage',
      priority: 'high'
    });

    return recommendations;
  }

  getGeneralRecommendations(context) {
    const recommendations = [];

    recommendations.push({
      action: 'Run automated tests',
      reason: 'Ensure changes don\'t break existing functionality',
      priority: 'high'
    });

    recommendations.push({
      action: 'Review code with team',
      reason: 'Peer review helps catch issues early',
      priority: 'medium'
    });

    return recommendations;
  }
}

// Export the hook
module.exports = {
  execute: async (context) => {
    const hook = new LegacyMigrationPostToolUseHook();
    return await hook.execute(context);
  }
};