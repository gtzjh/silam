#!/usr/bin/env python3
"""
SILAM代码规范自动检查工具

用法：
    python3 check_code_standards.py [source_directory]

检查项：
1. 文件命名规范
2. 模块声明与文件名一致性
3. 分层依赖规则（SILJA不依赖SILAM）
4. 基本代码风格
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple

class CodeStandardChecker:
    def __init__(self, source_dir: str):
        self.source_dir = Path(source_dir)
        self.errors = []
        self.warnings = []

    def check_all(self) -> Tuple[List[str], List[str]]:
        """运行所有检查"""
        self.check_file_naming()
        self.check_module_declaration()
        self.check_layering_dependencies()
        self.check_basic_style()
        return self.errors, self.warnings

    def check_file_naming(self):
        """检查文件命名规范"""
        print("检查文件命名规范...")

        valid_patterns = [
            r'^[a-z_]+\.silam\.mod\.f90$',      # SILAM模块
            r'^[a-z_]+\.silja\.mod\.f90$',      # SILJA模块
            r'^cbm\d+(_strato)?_SOA_\w+\.f90$', # 化学机制
            r'^[a-z_0-9]+\.f90$',               # 其他模块/程序
        ]

        for f in self.source_dir.glob('*.f90'):
            name = f.name
            is_valid = any(re.match(pattern, name) for pattern in valid_patterns)

            if not is_valid:
                self.errors.append(
                    f"命名不符合规范: {name}\n"
                    f"  应使用: <name>.silam.mod.f90 或 <name>.silja.mod.f90"
                )

    def check_module_declaration(self):
        """检查模块声明与文件名一致性"""
        print("检查模块声明...")

        for f in self.source_dir.glob('*.f90'):
            try:
                with open(f, 'r', encoding='latin-1', errors='ignore') as file:
                    # 读取前3000字符查找模块声明
                    content = file.read(3000)

                    # 跳过主程序
                    if re.search(r'^\s*(PROGRAM|program)\s+', content, re.MULTILINE):
                        continue

                    # 查找模块声明
                    module_match = re.search(
                        r'^\s*(MODULE|module)\s+(\w+)',
                        content,
                        re.MULTILINE
                    )

                    if module_match:
                        module_name = module_match.group(2).lower()
                        file_base = f.stem.split('.')[0].lower()

                        if module_name != file_base:
                            self.warnings.append(
                                f"模块名与文件名不匹配: {f.name}\n"
                                f"  文件: {file_base} vs 模块: {module_name}"
                            )
            except Exception as e:
                self.warnings.append(f"无法读取文件 {f.name}: {e}")

    def check_layering_dependencies(self):
        """检查分层依赖规则"""
        print("检查分层依赖...")

        # 检查SILJA模块不应依赖SILAM模块
        for f in self.source_dir.glob('*.silja.mod.f90'):
            try:
                with open(f, 'r', encoding='latin-1', errors='ignore') as file:
                    for i, line in enumerate(file, 1):
                        # 查找USE语句
                        use_match = re.match(
                            r'^\s*USE\s+(\w+)',
                            line,
                            re.IGNORECASE
                        )
                        if use_match:
                            used_module = use_match.group(1).lower()

                            # 检查是否使用了SILAM特定模块
                            silam_keywords = [
                                'chemistry_manager', 'dispersion_',
                                'source_terms_', 'field_buffer',
                                'observation_', 'da_', 'ensemble_'
                            ]

                            for keyword in silam_keywords:
                                if keyword in used_module:
                                    self.errors.append(
                                        f"SILJA模块依赖SILAM模块: {f.name}:{i}\n"
                                        f"  USE {used_module} 违反分层原则"
                                    )
                                    break
            except Exception as e:
                self.warnings.append(f"无法检查依赖 {f.name}: {e}")

    def check_basic_style(self):
        """检查基本代码风格"""
        print("检查代码风格...")

        for f in self.source_dir.glob('*.f90'):
            # 跳过KPP生成的代码
            if 'cbm' in f.name and 'SOA' in f.name:
                continue

            try:
                with open(f, 'r', encoding='latin-1', errors='ignore') as file:
                    lines = file.readlines()

                    # 检查前50行是否有注释头
                    has_header_comment = False
                    for i, line in enumerate(lines[:50]):
                        if 'Description:' in line or 'Author:' in line:
                            has_header_comment = True
                            break

                    if not has_header_comment:
                        self.warnings.append(
                            f"缺少头部注释: {f.name}\n"
                            f"  建议添加模块描述和作者信息"
                        )

                    # 检查是否有USE语句但没有IMPLICIT NONE
                    has_use = any('use ' in line.lower() or 'USE ' in line
                                  for line in lines[:100])
                    has_implicit_none = any('implicit none' in line.lower()
                                           for line in lines[:100])

                    if has_use and not has_implicit_none:
                        self.warnings.append(
                            f"缺少 IMPLICIT NONE: {f.name}"
                        )

            except Exception as e:
                pass  # 风格检查失败不影响主要检查


def main():
    # 确定源代码目录
    if len(sys.argv) > 1:
        source_dir = sys.argv[1]
    else:
        # 默认相对于脚本位置
        script_dir = Path(__file__).parent
        source_dir = script_dir.parent.parent / 'source'

    if not Path(source_dir).exists():
        print(f"错误：源代码目录不存在: {source_dir}")
        sys.exit(1)

    print(f"检查SILAM代码规范: {source_dir}")
    print("=" * 60)

    checker = CodeStandardChecker(source_dir)
    errors, warnings = checker.check_all()

    print("\n" + "=" * 60)

    # 输出结果
    if errors:
        print(f"\n❌ 发现 {len(errors)} 个错误:")
        for i, err in enumerate(errors, 1):
            print(f"\n{i}. {err}")

    if warnings:
        print(f"\n⚠️  发现 {len(warnings)} 个警告:")
        for i, warn in enumerate(warnings, 1):
            print(f"\n{i}. {warn}")

    if not errors and not warnings:
        print("\n✅ 所有检查通过！")
        return 0
    elif not errors:
        print(f"\n✅ 无错误（{len(warnings)} 个警告可忽略）")
        return 0
    else:
        print(f"\n❌ 检查失败：{len(errors)} 个错误，{len(warnings)} 个警告")
        return 1


if __name__ == '__main__':
    sys.exit(main())
