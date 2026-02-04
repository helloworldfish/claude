/**
 * 安全检查钩子 - 简化的安全验证
 *
 * 在工具执行前进行基本的安全检查
 */

class SafetyCheckHook {
  async execute(context) {
    const { tool, toolInput } = context;

    // 基本安全检查
    if (tool.name === 'Edit' || tool.name === 'Write') {
      // 检查是否是受保护的文件
      const protectedFiles = ['package-lock.json', 'yarn.lock', 'pom.xml'];
      const fileName = toolInput.path || toolInput.file_path;

      if (fileName && protectedFiles.some(pf => fileName.includes(pf))) {
        console.warn(`⚠️  跳过对受保护文件的修改: ${fileName}`);
        return { skip: true, reason: 'Protected file' };
      }
    }

    return { proceed: true };
  }
}

module.exports = SafetyCheckHook;