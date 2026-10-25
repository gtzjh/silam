# SILAM项目结构分析与开发规范

## 1. 项目概况

SILAM（System for Integrated modeLling of Atmospheric coMposition）是芬兰气象研究所（FMI）开发的大气化学传输模型，用于模拟大气污染物的扩散、转化和沉降。

### 1.1 技术栈
- **语言**：Fortran 90/95（167个源文件）
- **构建系统**：GNU Make
- **编译器支持**：GCC (gfortran)、Intel Fortran、多种HPC系统
- **外部依赖**：
  - eccodes（GRIB数据格式）
  - NetCDF（科学数据IO）
  - LAPACK/BLAS（线性代数）
  - PROJ（地图投影）
  - BZip2（压缩）
- **化学机制**：KPP（Kinetic PreProcessor）生成的代码

### 1.2 代码规模统计
```
总源文件数：167个 .f90 文件
模块文件：103个 .mod.f90
  - SILAM模块：53个 (.silam.mod.f90)
  - SILJA模块：32个 (.silja.mod.f90)
  - 其他模块：18个
主程序：4个（主模型、箱模型、工具程序）
```

---

## 2. 目录结构与职责

### 2.1 核心目录

```
silam/
├── source/           # 所有Fortran源代码（167文件）
├── build/            # 构建系统和编译配置
│   ├── makefile      # 主Makefile
│   ├── options.*     # 各平台编译选项
│   └── makefile.*    # 子系统构建规则
├── bin/              # 可执行文件输出目录
├── obj/              # 编译中间文件（.o, .mod）
│   └── <compiler>/   # 按编译器分类
├── kpp/              # KPP化学机制生成器
│   ├── cbm5_SOA/     # CBM5机制+SOA
│   ├── cbm7_SOA/     # CBM7机制+SOA
│   ├── src/          # KPP源码
│   └── int/          # 积分器
├── ini/              # 运行时配置文件
├── doc/              # 文档（LaTeX）
└── .tmp/             # 临时文件（不提交）
```

### 2.2 目录职责说明

| 目录 | 用途 | 是否提交Git |
|------|------|-------------|
| `source/` | 唯一的源代码目录 | ✓ |
| `build/` | 构建配置和Makefile | ✓ |
| `kpp/cbm*/` | KPP生成的化学代码 | ✗ (生成文件) |
| `kpp/src/` | KPP生成器源码 | ✓ |
| `bin/` | 编译产物 | ✗ |
| `obj/` | 中间编译文件 | ✗ |
| `.tmp/` | 临时工作文件 | ✗ |

---

## 3. 源代码组织规则

### 3.1 命名约定

SILAM采用**三层命名体系**：

#### **文件命名格式**
```
<module_name>.<library>.<type>.f90

例如：
- chemistry_manager.silam.mod.f90    # SILAM模块
- fields.silja.mod.f90                # SILJA模块  
- box_model.f90                       # 独立程序
```

#### **命名层次**
1. **SILJA层**（`.silja.mod.f90`）
   - 通用基础库，与具体应用无关
   - 例子：`globals.silja.mod.f90`, `fields.silja.mod.f90`
   - 特点：不依赖SILAM特定业务逻辑

2. **SILAM层**（`.silam.mod.f90`）
   - 应用层模块，实现SILAM特定功能
   - 例子：`chemistry_manager.silam.mod.f90`
   - 特点：可以依赖SILJA层，包含业务逻辑

3. **工具程序层**（`.f90`）
   - 独立程序或工具
   - 例子：`box_model.f90`, `ascii_2_nc.f90`
   - 特点：包含PROGRAM主程序

#### **化学机制文件**
KPP生成的代码有独特命名：
```
cbm5_SOA_<Component>.f90

例如：
- cbm5_SOA_Global.f90
- cbm5_SOA_Integrator.f90
- cbm5_SOA_Jacobian.f90
```

### 3.2 文件放置规则

**核心原则：所有源代码集中在`source/`目录**

```
✓ 正确：
  source/new_module.silam.mod.f90
  
✗ 错误：
  source/utils/new_module.f90        # 不应创建子目录
  new_module.f90                     # 不应放在根目录
```

### 3.3 模块结构模板

#### SILJA模块模板
```fortran
MODULE <module_name>
  !
  ! Description:
  ! [模块功能简述]
  !
  ! Author: [姓名], FMI
  !
  ! Language: ANSI standard Fortran 90
  ! Units: SI
  !

  ! Modules used:
  USE natural_constants
  USE max_sizes_and_limits
  
  IMPLICIT NONE
  
  PRIVATE
  
  ! Public interfaces
  PUBLIC :: <public_functions>
  
  ! Module contents...
  
END MODULE <module_name>
```

#### SILAM模块模板
```fortran
module <module_name>
  !
  ! The module [功能描述]
  !
  ! Code owners: [姓名], email <firstname>.<lastname>@fmi.fi
  !
  ! Units: SI
  ! Code: ANSI FORTRAN-90 (or close to it)
  !

  use <silja_modules>
  use <silam_modules>
  
  implicit none
  
  private
  
  ! Public exports...
  
  ! Module implementation...
  
end module <module_name>
```

---

## 4. 架构分层与依赖规则

### 4.1 分层架构

```
┌─────────────────────────────────────┐
│   应用层 (SILAM)                      │
│   chemistry_manager, dispersion_*    │
│   [业务逻辑]                          │
└──────────────┬──────────────────────┘
               │ 依赖
┌──────────────▼──────────────────────┐
│   库层 (SILJA)                        │
│   fields, grids_geo, globals         │
│   [通用功能]                          │
└──────────────┬──────────────────────┘
               │ 依赖
┌──────────────▼──────────────────────┐
│   基础层                              │
│   natural_constants, max_sizes       │
│   [常量和限制]                        │
└─────────────────────────────────────┘
```

### 4.2 依赖规则

#### **允许的依赖方向**

```
✓ SILAM模块 → SILJA模块
✓ SILAM模块 → 基础层（natural_constants等）
✓ SILJA模块 → 基础层
✓ 同层模块之间（需要避免循环依赖）

✗ SILJA模块 → SILAM模块（违反分层原则）
✗ 基础层 → 任何上层模块
```

#### **常用核心依赖**

从源代码分析中提取的最常用模块：
```fortran
! 基础层（几乎所有模块都需要）
USE natural_constants
USE max_sizes_and_limits
USE globals

! SILJA常用模块
USE fields                    ! 场数据结构
USE grids_geo                ! 网格和地理投影
USE field_identifications    ! 场标识和元数据
USE silam_times              ! 时间处理

! SILAM常用模块
USE dispersion_models        ! 主调度器
USE chemistry_manager        ! 化学转化管理
USE field_buffer            ! 场数据缓冲
```

#### **禁止的依赖模式**

1. **循环依赖**
   ```
   ✗ module_a依赖module_b，同时module_b依赖module_a
   ```

2. **越层依赖**
   ```
   ✗ SILJA层直接调用SILAM特定功能
   ```

3. **化学机制交叉依赖**
   ```
   ✗ 不同化学机制（CBM5, CBM7）之间互相依赖
   ```

---

## 5. 构建系统规则

### 5.1 构建流程

#### **标准编译过程**
```bash
cd source/
make gnu              # 生成配置（首次或修改选项后）
make                  # 编译主模型
make box              # 编译箱模型
make ascii2nc         # 编译工具程序
```

#### **构建系统文件职责**

| 文件 | 职责 |
|------|------|
| `build/makefile` | 主控Makefile，处理依赖关系 |
| `build/options.*` | 平台特定编译选项（FFLAGS等） |
| `build/makefile.model` | 主模型构建规则 |
| `build/makefile.box` | 箱模型构建规则 |
| `build/silam_main.rules.full` | 完整依赖关系（自动生成） |

### 5.2 添加新源文件的规则

#### **自动识别机制**
构建系统会自动扫描`source/`目录中的`.f90`文件，因此：

✓ **需要做的**：
1. 将新文件放入`source/`目录
2. 遵循命名约定
3. 正确声明模块名（必须与文件名匹配）

✗ **不需要做的**：
1. 手动修改Makefile添加文件列表
2. 手动声明依赖关系（会自动分析）

#### **依赖关系自动生成**
```bash
# 构建系统会分析USE语句自动生成依赖
# 生成文件：build/silam_main.rules.full
```

#### **特殊情况：化学机制代码**
KPP生成的代码需要特殊处理：
```bash
# 进入化学机制目录
cd kpp/cbm5_SOA/
# 运行KPP生成Fortran代码
../../bin/kpp cbm5_SOA.kpp
# 生成的.f90文件会被主构建系统自动识别
```

### 5.3 编译选项配置

#### **平台选择**
```bash
# GCC编译器
make SETUP=gnu

# Intel编译器
make SETUP=intel

# MPI并行版本
make SETUP=gnumpi

# 调试版本
make SETUP=gnu_debug
```

#### **自定义编译选项**
编辑`build/options.<SETUP>`：
```makefile
# 优化级别
OPTIMIZATION = -O3 -fopenmp -ffast-math

# 调试选项
DEBUG = -g -fbacktrace

# 预处理器定义
PREPROCESS = -x f95-cpp-input -D WITH_BZIP2 -DUSE_PROJ6

# Include路径
INCLUDE = -I$(OBJDIR) -I/usr/include
```

---

## 6. 开发工作流规范

### 6.1 添加新功能模块

#### **步骤1：确定模块层次**
```
问题检查清单：
□ 这是通用功能还是SILAM特定功能？
  → 通用 → 使用.silja.mod.f90
  → 特定 → 使用.silam.mod.f90
  
□ 需要依赖哪些现有模块？
  → 检查是否违反分层原则
  
□ 是否与化学机制相关？
  → 是 → 考虑放入chemistry_manager体系
```

#### **步骤2：创建文件**
```bash
# 示例：添加新的排放源模块
cd source/
touch source_terms_agriculture.silam.mod.f90
```

#### **步骤3：编写模块骨架**
```fortran
module source_terms_agriculture
  !
  ! Agricultural emission source term handler
  !
  ! Code owner: Your Name, email your.name@institution.fi
  !
  ! Units: SI
  ! Code: ANSI FORTRAN-90
  !

  use source_terms_general  ! SILAM源项基类
  use cocktail_basic        ! SILJA物质定义
  use fields                ! SILJA场操作
  
  implicit none
  
  private
  
  public :: init_agriculture_source
  public :: add_agriculture_emission
  
contains

  subroutine init_agriculture_source(source, nlptr)
    ! Implementation...
  end subroutine init_agriculture_source
  
end module source_terms_agriculture
```

#### **步骤4：集成到系统**
修改调用模块（如`chemistry_manager`或`source_terms_general`）：
```fortran
use source_terms_agriculture  ! 添加依赖

! 在适当位置调用新模块接口
call init_agriculture_source(...)
```

#### **步骤5：编译验证**
```bash
cd source/
make clean
make
# 检查编译错误和警告
```

### 6.2 修改现有模块

#### **小规模修改（<50行）**
```bash
# 1. 直接编辑文件
vim source/module_name.silam.mod.f90

# 2. 增量编译
make

# 3. 如果出现依赖错误，重新生成规则
make clean
make gnu
make
```

#### **大规模重构**
```bash
# 1. 在新分支上工作
git checkout -b feature/refactor-module-name

# 2. 修改代码

# 3. 完整重新编译
make clean
rm build/silam_main.rules.full
make gnu
make

# 4. 回归测试
./bin/silam_v6_1pub.gnu < test_case.ini
```

### 6.3 Git工作流

#### **分支策略**
```
silam_v6_1pub (主分支) ← 一般不直接提交
    ↓
feature/your-feature   ← 在这里开发
```

#### **提交规范**
```bash
# 创建功能分支
git checkout -b feature/add-agriculture-source

# 分阶段提交
git add source/source_terms_agriculture.silam.mod.f90
git commit -m "Add agricultural emission source module skeleton"

git add source/chemistry_manager.silam.mod.f90
git commit -m "Integrate agriculture source into chemistry manager"

# 推送前检查
git status  # 确保没有提交.o, .mod文件
```

#### **不应提交的文件**
```
✗ bin/silam_*           # 可执行文件
✗ obj/**/*.o            # 编译中间文件
✗ obj/**/*.mod          # 模块接口文件
✗ .tmp/**/*             # 临时文件
✗ kpp/cbm*/*.f90        # KPP生成的代码（除非是修改后的）
```

---

## 7. 代码风格约定

### 7.1 Fortran语法规则

#### **大小写约定**
```fortran
! SILJA风格（旧代码）- 大写关键字
MODULE MyModule
  USE OtherModule
  IMPLICIT NONE
  REAL :: value
END MODULE MyModule

! SILAM风格（新代码）- 小写关键字（推荐）
module my_module
  use other_module
  implicit none
  real :: value
end module my_module
```

**规则**：新代码使用小写，修改旧代码时保持原风格一致。

#### **缩进和格式**
```fortran
! 使用2空格缩进
module example
  implicit none
  
  private
  public :: process_data
  
contains
  
  subroutine process_data(input, output)
    real, dimension(:), intent(in) :: input
    real, dimension(:), intent(out) :: output
    integer :: i
    
    do i = 1, size(input)
      if (input(i) > 0.0) then
        output(i) = sqrt(input(i))
      else
        output(i) = 0.0
      end if
    end do
    
  end subroutine process_data
  
end module example
```

#### **注释规范**
```fortran
! 文件头部注释（必须）
module my_module
  !
  ! Description: [详细描述模块功能]
  !
  ! [可选：算法说明、参考文献]
  !
  ! Code owner: Name, email
  ! Units: SI
  ! Code: ANSI FORTRAN-90
  !

! 重要函数注释（推荐）
  subroutine complex_calculation(param1, param2, result)
    !
    ! Calculates [具体计算内容]
    !
    ! Arguments:
    !   param1 - [说明]
    !   param2 - [说明]
    !   result - [说明]
    !
    ! Method: [如果算法复杂，说明方法]
    !
```

### 7.2 命名约定

#### **变量命名**
```fortran
! 推荐的命名风格
integer :: i, j, k                    ! 循环变量
integer :: iStatus, iTime, iSpecies   ! 整数变量（i前缀）
real :: fTemperature, fPressure       ! 浮点变量（f前缀）
logical :: ifValid, ifFound           ! 布尔变量（if前缀）
character(len=fnlen) :: chFileName    ! 字符串（ch前缀）
type(silja_time) :: valid_time        ! 类型实例（下划线分隔）
```

#### **常量命名**
```fortran
! 全大写+下划线
real, parameter :: GAS_CONSTANT_R = 8.314
integer, parameter :: MAX_SPECIES = 1000
```

#### **函数/子程序命名**
```fortran
! 动词开头，下划线分隔
subroutine init_emission_source(...)
subroutine compute_deposition_rate(...)
function get_grid_cell_area(grid, ix, iy) result(area)
```

### 7.3 性能考虑

#### **数组操作**
```fortran
! ✓ 推荐：使用数组切片
concentration(1:nx, 1:ny) = concentration(1:nx, 1:ny) * factor

! ✗ 避免：显式循环（除非必要）
do j = 1, ny
  do i = 1, nx
    concentration(i,j) = concentration(i,j) * factor
  end do
end do
```

#### **OpenMP并行**
```fortran
! 在计算密集的循环使用OpenMP
!$OMP PARALLEL DO PRIVATE(i, j)
do j = 1, ny
  do i = 1, nx
    ! 计算...
  end do
end do
!$OMP END PARALLEL DO
```

---

## 8. 测试与验证

### 8.1 测试策略

#### **编译测试**
```bash
# 测试所有编译配置
make SETUP=gnu clean && make SETUP=gnu
make SETUP=gnu_debug clean && make SETUP=gnu_debug
make SETUP=intel clean && make SETUP=intel
```

#### **运行时测试**
使用toypoint测试案例：
```bash
# 获取测试案例
git clone https://github.com/fmidev/silam-toypoint

# 运行基准测试
cd silam-toypoint/
../bin/silam_v6_1pub.gnu control.ini

# 检查输出
ls output/
# 应该生成GRIB/NetCDF输出文件
```

#### **箱模型测试**
用于快速验证化学机制：
```bash
./bin/box_model.gnu < box_test.ini
```

### 8.2 调试技巧

#### **编译时调试**
```bash
# 使用调试配置
make SETUP=gnu_debug

# 运行时检查
ulimit -s unlimited  # 增加栈大小
gdb --args bin/silam_v6_1pub.gnu_debug control.ini
```

#### **运行时诊断**
```fortran
! 在代码中添加诊断输出
if (error_status /= 0) then
  call msg('Error in module_name at step:', iStep)
  call set_error('Detailed error message', 'subroutine_name')
  return
end if
```

### 8.3 性能分析

#### **时间剖析**
```bash
# 使用gprof
make SETUP=gnu FFLAGS="-pg -O2"
./bin/silam_v6_1pub.gnu < control.ini
gprof bin/silam_v6_1pub.gnu gmon.out > analysis.txt
```

#### **内存分析**
```bash
valgrind --leak-check=full --track-origins=yes \
  ./bin/silam_v6_1pub.gnu_debug < control.ini
```

---

## 9. 规范自动化检查

### 9.1 检查脚本设计

创建验证脚本`scripts/check_code_standards.py`：

```python
#!/usr/bin/env python3
"""
SILAM代码规范检查工具
"""
import os
import re
from pathlib import Path

def check_file_naming(source_dir):
    """检查文件命名规范"""
    errors = []
    for f in Path(source_dir).glob('*.f90'):
        name = f.name
        # 检查命名模式
        if not (name.endswith('.silam.mod.f90') or 
                name.endswith('.silja.mod.f90') or
                re.match(r'^[a-z_]+\.f90$', name) or
                re.match(r'^cbm\d+.*\.f90$', name)):
            errors.append(f"命名不符合规范: {name}")
    return errors

def check_module_declaration(source_dir):
    """检查模块声明与文件名一致性"""
    errors = []
    for f in Path(source_dir).glob('*.f90'):
        with open(f, 'r', encoding='latin-1') as file:
            content = file.read(2000)  # 读取前2000字符
            module_match = re.search(r'^(MODULE|module)\s+(\w+)', 
                                     content, re.MULTILINE)
            if module_match:
                module_name = module_match.group(2)
                expected_prefix = module_name.lower()
                if not f.stem.startswith(expected_prefix):
                    errors.append(
                        f"模块名不匹配: {f.name} contains module {module_name}"
                    )
    return errors

def check_dependencies(source_dir):
    """检查SILJA不依赖SILAM"""
    errors = []
    for f in Path(source_dir).glob('*.silja.mod.f90'):
        with open(f, 'r', encoding='latin-1') as file:
            for i, line in enumerate(file, 1):
                if re.search(r'^\s*use\s+\w+.*\.silam\.', line, re.I):
                    errors.append(
                        f"SILJA模块依赖SILAM: {f.name}:{i}"
                    )
    return errors

if __name__ == '__main__':
    source_dir = '../source'
    all_errors = []
    
    all_errors.extend(check_file_naming(source_dir))
    all_errors.extend(check_module_declaration(source_dir))
    all_errors.extend(check_dependencies(source_dir))
    
    if all_errors:
        print("发现规范问题:")
        for err in all_errors:
            print(f"  ⚠ {err}")
        exit(1)
    else:
        print("✓ 所有检查通过")
        exit(0)
```

### 9.2 预提交钩子

创建`.git/hooks/pre-commit`：
```bash
#!/bin/bash
# SILAM代码预提交检查

echo "运行代码规范检查..."

# 检查是否提交了不应提交的文件
if git diff --cached --name-only | grep -E '(\.o|\.mod|^bin/|^obj/)'; then
    echo "错误：不应提交编译产物"
    exit 1
fi

# 检查SILAM特定规范
if [ -f scripts/check_code_standards.py ]; then
    python3 scripts/check_code_standards.py
    if [ $? -ne 0 ]; then
        echo "错误：代码不符合SILAM规范"
        exit 1
    fi
fi

echo "✓ 预提交检查通过"
```

---

## 10. 常见问题与解决方案

### 10.1 编译问题

#### **问题：找不到模块文件**
```
Error: Can't open module file 'grib_api.mod'
```

**原因**：系统库的.mod文件不在编译器搜索路径

**解决**：
```bash
# 方法1：修改build/options.gnu
INCLUDE = -I$(OBJDIR) -I/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15

# 方法2：创建符号链接
sudo ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod \
           /usr/lib/gcc/x86_64-linux-gnu/10/finclude/
```

#### **问题：循环依赖**
```
Error: Circular dependency detected
```

**排查步骤**：
1. 检查`build/silam_main.rules.full`中的依赖链
2. 重构代码，将共同依赖提取到独立模块
3. 使用接口抽象打破循环

### 10.2 运行时问题

#### **问题：栈溢出**
```
Segmentation fault (core dumped)
```

**解决**：
```bash
# 增加栈大小
ulimit -s unlimited

# 或使用OpenMP线程栈控制
export OMP_STACKSIZE=100M
```

#### **问题：内存不足**
**优化策略**：
- 减少模拟域大小
- 降低垂直层数
- 减少物种数量
- 使用MPI分布式计算

### 10.3 集成问题

#### **添加新模块后编译失败**

**检查清单**：
```bash
# 1. 文件名是否正确
ls -l source/your_module.silam.mod.f90

# 2. 模块名是否匹配
grep "^module" source/your_module.silam.mod.f90

# 3. 依赖是否正确
grep "use " source/your_module.silam.mod.f90

# 4. 重新生成依赖关系
rm build/silam_main.rules.full
make gnu

# 5. 完全重新编译
make clean
make
```

---

## 11. 架构扩展指南

### 11.1 添加新的物理/化学过程

**场景**：实现新的气溶胶动力学方案

**步骤**：

1. **创建过程模块**
```fortran
! source/aerosol_dynamics_advanced.f90
module aer_dyn_advanced
  use aer_dyn_basic  ! 继承基类接口
  
  implicit none
  private
  public :: init_AerDynAdvanced
  public :: transform_AerDynAdvanced
  
contains
  ! 实现接口...
end module aer_dyn_advanced
```

2. **注册到管理器**
```fortran
! 修改 source/chemistry_manager.silam.mod.f90
use aer_dyn_advanced

! 在初始化部分添加
case('ADVANCED_AEROSOL')
  call init_AerDynAdvanced(...)
```

3. **配置文件支持**
```ini
# ini/control.ini
transformation = ADVANCED_AEROSOL
```

### 11.2 添加新的数据格式支持

**场景**：添加HDF5输出支持

1. **创建IO模块**
```fortran
! source/hdf5_io.silam.mod.f90
module hdf5_io
  use fields
  implicit none
  public :: write_field_to_hdf5
```

2. **集成到输出系统**
```fortran
! 修改 source/io_server.silam.mod.f90
use hdf5_io

select case(output_format)
  case(hdf5_file_flag)
    call write_field_to_hdf5(...)
```

### 11.3 添加新的排放源类型

遵循`source_terms_*.silam.mod.f90`模式：

```fortran
module source_terms_new_type
  use source_terms_general
  
  ! 实现source_term基类的所有必需接口：
  ! - init_source
  ! - add_emission_flux
  ! - project_source_to_grid
  
end module source_terms_new_type
```

---

## 12. 文档维护

### 12.1 代码文档

**必须文档化的内容**：
- 模块头部：功能、作者、单位
- 复杂算法：数学公式、参考文献
- 公共接口：参数说明、使用示例

**LaTeX文档**：
```bash
cd doc/assimilation/
make  # 生成PDF文档
```

### 12.2 架构决策记录

对重大设计决策建议使用ADR（Architecture Decision Records）：

```markdown
# ADR 001: 采用分层模块架构

## 状态
已接受

## 背景
代码库增长导致依赖混乱...

## 决策
引入SILJA/SILAM两层架构...

## 后果
正面：模块解耦、易于测试
负面：初期重构成本
```

---

## 13. 总结：新开发者快速清单

### 13.1 环境搭建（5分钟）
```bash
# 1. 克隆代码
git clone https://github.com/fmidev/silam-model.git
cd silam-model

# 2. 安装依赖
sudo apt install gfortran libeccodes-dev libnetcdff-dev liblapack-dev

# 3. 编译
cd source/
make gnu
make
```

### 13.2 第一次代码修改（30分钟）
```bash
# 1. 创建功能分支
git checkout -b feature/my-first-change

# 2. 编辑文件
vim source/existing_module.silam.mod.f90

# 3. 编译测试
make

# 4. 运行验证
cd ../silam-toypoint/
../bin/silam_v6_1pub.gnu control.ini

# 5. 提交
git add source/existing_module.silam.mod.f90
git commit -m "My first change"
```

### 13.3 核心规则记忆
✓ **DO**：
- 所有源码放`source/`
- 使用`.silam.mod.f90`或`.silja.mod.f90`命名
- 遵循分层依赖（SILAM→SILJA→基础）
- 单位使用SI
- 提交前`make clean && make`

✗ **DON'T**：
- 创建source子目录
- 提交.o/.mod文件
- SILJA依赖SILAM
- 硬编码常量
- 跳过编译测试

---

## 附录A：完整目录树

```
silam/
├── source/               # 167个.f90源文件
│   ├── *.silam.mod.f90  # 53个SILAM模块
│   ├── *.silja.mod.f90  # 32个SILJA模块
│   ├── cbm*_SOA_*.f90   # 化学机制代码（KPP生成）
│   ├── *_main.f90       # 主程序入口
│   └── *.f90            # 其他模块和工具
│
├── build/               # 构建系统
│   ├── makefile         # 主Makefile
│   ├── options.gnu      # GCC编译选项
│   ├── options.intel    # Intel编译选项
│   ├── makefile.model   # 模型构建规则
│   └── *.rules.full     # 依赖关系（自动生成）
│
├── kpp/                 # KPP化学预处理器
│   ├── src/             # KPP源码
│   ├── cbm5_SOA/        # CBM5机制定义
│   ├── cbm7_SOA/        # CBM7机制定义
│   └── int/             # 数值积分器
│
├── bin/                 # 可执行文件（不提交）
├── obj/                 # 编译中间文件（不提交）
│   └── gnu/             # 按编译器分类
├── ini/                 # 配置文件模板
├── doc/                 # 文档（LaTeX）
└── .tmp/                # 临时文件（不提交）
```

## 附录B：关键模块依赖图

```
dispersion_models (主调度)
    ↓
chemistry_manager
    ├→ chem_dep_cbm5_SOA
    ├→ aer_dyn_basic
    └→ depositions
        ↓
field_buffer ← field_identifications
    ↓           ↓
  fields ← grids_geo
    ↓
  globals ← natural_constants
```

## 附录C：文件命名速查表

| 用途 | 命名格式 | 示例 |
|------|----------|------|
| SILAM模块 | `<name>.silam.mod.f90` | `chemistry_manager.silam.mod.f90` |
| SILJA模块 | `<name>.silja.mod.f90` | `fields.silja.mod.f90` |
| 主程序 | `<name>.f90` | `silam_main.f90` |
| 工具程序 | `<name>.f90` | `ascii_2_nc.f90` |
| 化学机制 | `cbm<N>_<detail>_<comp>.f90` | `cbm5_SOA_Integrator.f90` |

---

**文档版本**：1.0  
**最后更新**：2024-10-25  
**维护者**：基于silam-model项目分析生成  
**联系**：参考FMI SILAM团队
