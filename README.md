# Silam public distribution

This checkout is maintained for atmospheric pollen simulations. It keeps the
SILAM main model, shared transport and deposition code, and the existing
generated chemistry solvers.

KPP code generation, the chemistry box model, fire preprocessing, standalone
format converters, lagged-input tools, and old platform configurations have
been removed. GNU release, debug, and MPI configurations remain available.
The bundled photolysis lookup table and dedicated non-pollen examples are
omitted; CBM chemistry runs require an external compatible lookup table.
Pollen templates still require suitable meteorological, vegetation, and
phenological inputs for the selected case.

本项目仅在根目录维护 `README.md` 和 `.gitignore`。目录说明集中在本页，专题开发文档保留在 `docs/dev/`；执行与维护规则见 [AGENTS.md](AGENTS.md)。

## 目录

- [开发指南](#development)
- [Ubuntu 编译](#building-silam)
- [编译问题排查](#troubleshooting)
- [测试代码](#tests)
- [运行资源与配置示例](#runtime-resources)
- [ecCodes 本地定义说明](#eccodes-definitions)
- [点源案例（daemon/）](#toypoint)

<a id="development"></a>

## 开发指南

本页提供开发文档入口和日常速查。

[AGENTS.md](AGENTS.md) 统一规定授权、分支、worktree、验证和临时文件规则。`docs/dev/` 提供技术细节。长期技术结论写入对应主题文档，不维护独立任务日志或 MEMORY。

### 开发文档

| 文档 | 内容 |
|------|------|
| [项目结构与架构](docs/dev/项目结构与架构.md) | 项目概况、目录职责、分层依赖、目录树和依赖图 |
| [源码组织与命名](docs/dev/源码组织与命名.md) | 文件命名、源文件放置、模块模板和命名速查表 |
| [构建系统](docs/dev/构建系统.md) | 构建流程、源文件识别、依赖生成和编译选项 |
| [开发流程](docs/dev/开发流程.md) | 新增与修改模块、Git工作流、提交检查和首次开发清单 |
| [代码风格与文档](docs/dev/代码风格与文档.md) | Fortran风格、命名、性能建议、代码文档和长期技术结论 |
| [测试与调试](docs/dev/测试与调试.md) | 编译与运行测试、调试、性能分析和常见问题 |
| [架构扩展](docs/dev/架构扩展.md) | 新增物理化学过程、数据格式和排放源类型 |
| [实际命名模式分析](docs/dev/实际命名模式分析.md) | 历史命名变体、特殊模块和现有依赖问题 |

新开发者可先阅读项目结构与架构、构建系统，其余文档按需查阅。日常速查见下文。

### 文件命名与分层

```text
SILAM模块：  <name>.silam.mod.f90
SILJA模块：  <name>.silja.mod.f90
主程序：     <name>.f90
化学机制：   cbm<N>_<detail>_<Component>.f90
```

生产源码按功能放在 `src/` 的子目录，测试子模块和三个独立测试程序放在 `tests/` 的对应功能目录；主程序 `src/silam_main.f90` 保留在根层。目录职责见[项目结构与架构](docs/dev/项目结构与架构.md)，测试命名和构建入口见[测试目录说明](#tests)。

下面是历史分层的设计建议；功能目录不强制实现这些层次，现有源码也有跨层依赖，见[实际命名模式分析](docs/dev/实际命名模式分析.md)。

```text
✓ SILAM → SILJA → 基础层
✓ SILAM → 基础层
✗ SILJA → SILAM
✗ 基础层 → 任何上层
```

同层模块之间也应避免循环依赖。

### 常用编译命令

根目录 `Makefile` 是日常构建入口，`build/` 保留内部规则和编译配置。所选配置保存到本地 `build/DefaultSetup`。以下命令均在项目根目录执行：

```bash
# 首次编译：选择配置后构建
make gnu
make

# 增量编译
make

# 清理重编
make clean
make

# 调试版本：切换配置后构建
make gnu_debug
make

# 查看所选配置；使用完整依赖和8个编译任务构建
make what
make full

# 独立测试程序：也可将 PROGRAM 改为 test_enkf 或 test_perturb
make -C build -f makefile.generic PROGRAM=test_modules SETUP=gnu

# 编译并链接全部测试子模块，不自动执行测试
make -C build -f makefile.generic PROGRAM=silam_main SETUP=gnu
```

### Git工作流

默认在 `main` 开发，主目录保持 `main`。小任务直接执行；多阶段计划、跨模块协调、科学或数值行为变化等较大任务，先分析影响，再询问用户是否创建分支并放入 `.worktree/` 隔离。具体标准与操作见[开发流程](docs/dev/开发流程.md#任务大小与分支选择)。

agent 自行决定本地 commit 时机。隔离任务完成后，合并回 `main` 前必须获得用户明确同意；push 也必须获得用户明确同意。创建分支或 worktree 的同意不同时授权合并或 push。

提交前用 `git status` 检查改动，只提交本任务预期内容。`bin/`、`obj/`、`.tmp/`、`.worktree/` 和 `*.o`、`*.mod` 等编译产物不应提交。

### 添加新模块

1. 确定功能目录、模块职责及依赖方向，兼顾历史 SILAM/SILJA 命名。
2. 在 `src/` 对应功能目录创建文件，测试实现放在 `tests/` 的同名功能目录；参考[源码组织与命名](docs/dev/源码组织与命名.md)中的模块模板。
3. 实现并集成模块，使用 `make` 编译验证。
4. 运行与改动相关的测试；toypoint案例的配置和运行方法见 [toypoint说明](#toypoint)。
5. 更新受影响的文档，审查后按需要提交；隔离分支等待用户同意后再合并。

### 调试与常见问题

```bash
# 增加主线程和OpenMP线程的栈大小
ulimit -s unlimited
export OMP_STACKSIZE=100M
```

使用调试配置构建后，可通过 `gdb --args <可执行文件> <控制文件>` 调试。可执行文件位于 `bin/`，具体名称取决于构建配置。

| 问题 | 排查方向 |
|------|----------|
| 找不到模块文件 | 检查 `build/options.<配置名>` 中的库路径和编译器兼容性 |
| 循环依赖 | 检查 `build/silam_main.rules.full`，将共同依赖提取到独立模块 |
| 新模块编译失败 | 检查文件名、模块声明和依赖，必要时清理重编 |

### 关键文件位置

| 文件 | 用途 |
|------|------|
| `src/silam_main.f90` | 主程序入口 |
| `src/transport/dispersion_models.*.f90` | 主调度器 |
| `src/chem/chemistry_manager.*.f90` | 化学管理器 |
| `Makefile` | 编译配置选择和构建入口 |
| `tests/<功能目录>/test_*.f90` | 测试子模块及三个独立测试程序 |
| `build/makefile` | 内部构建总控 |
| `build/DefaultSetup` | 本地选择的编译配置（不提交） |
| `build/options.gnu` | GNU编译选项 |

### 提交前检查

- [ ] 文件命名、模块声明、分层依赖和接口符合开发规范。
- [ ] 已完成适用的检查，分别说明环境、编译、案例运行和数值回归的结果；未完成项标明未验证。
- [ ] `git status` 中没有待提交的编译产物或临时文件。
- [ ] 代码及受影响的文档已审查。

### 文档维护

架构、模块类型、构建方式或编码约定变化时，同步更新相应主题文档和本页；涉及历史命名或依赖问题时，更新实际命名模式分析。核对文档中的路径、命令和链接，并更新受影响文档的日期。

`docs/assimilation/` 保留同化说明文档的 LaTeX 和参考文献源码，当前不提供文档或 PDF 构建目标。

**最后更新**：2026-10-26

<a id="building-silam"></a>

## BUILDING SILAM v6_1 in Ubuntu  20.04, 22.04, 24.04

Get the source code

`$ git clone https://github.com/fmidev/silam-model.git`

Install needed packages

`$ sudo apt install make python3 gfortran libeccodes-dev libnetcdf-dev libnetcdff-dev liblapack-dev libblas-dev libbz2-dev libproj-dev`

Compile the binary

`$ cd silam-model/`

`$ make gnu`

`$ make`

The latter command might require a second try. Finally, it should create a binary in bin/,
that can be launched as:

`$ ./bin/silam_v6_1pub.gnu`

Silam should run and complain about missing silam.ini.
Then the binary is ready to use! You can test it with a test case from
https://github.com/fmidev/silam-toypoint



<a id="troubleshooting"></a>

## Troubleshooting

In Ubuntu one might get an error message like

`grib_api.mod not found`

There are several versions of gfortran available in 20.04. Some libraries
have headers in a location specific for "module version", where gfortran can't find them:

`/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/`

Others have them in gfortran-version-specific location

`/usr/lib/gcc/x86_64-linux-gnu/10/finclude/`

or

`/usr/lib/gcc/x86_64-linux-gnu/19/finclude/`

A workaround would be to either explicitly call FORTRAN with `-I
/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15` (by adding this option to
FFLAGS  in build/options.gnu).

or add symlinks to the needed .mod files to your gfortran include
directory (as root).

`# ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod /usr/lib/gcc/x86_64-linux-gnu/10/finclude/`

or

`# ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod /usr/lib/gcc/x86_64-linux-gnu/9/finclude/`

The exact command depends on your gcc version, which can be checked with
`$ gfortran -v`

The issue has been reported at
https://bugs.launchpad.net/ubuntu/+source/gcc-defaults/+bug/1883855.
Please consider confirming the bug if it affects you.

<a id="tests"></a>

## 测试代码

测试位于 `tests/`，按 `src/` 的功能目录组织；下表目录名均相对 `tests/`。每个原模块的测试实现放在同目录名下的 `test_<模块名>_impl.f90` 中，文件名与 Fortran 子模块名一致。当前有29个测试子模块和三个历史独立测试程序。

| 目录 | 子模块数 | 独立程序数 | 主要内容 |
|------|----------|------------|----------|
| `core/` | 2 | 0 | 工具函数、排序、最小化与时间 |
| `grid/` | 4 | 0 | 网格、位置、垂直层与投影 |
| `fields/` | 1 | 0 | 测试气象场存储 |
| `meteo/` | 3 | 0 | 热力学、垂直投影与派生气象场 |
| `transport/` | 3 | 1 | 平流、沉降及扩散测试钩子 |
| `emissions/` | 1 | 0 | DMS排放 |
| `chem/` | 3 | 0 | 物种配置、单位转换与光解 |
| `io/` | 1 | 0 | GRIB读写 |
| `assimilation/` | 10 | 2 | 同化、观测、集合、扰动及伴随 |
| `numerics/` | 1 | 0 | FISHPACK参考问题自检 |

原模块在 `src/` 保留匹配的 `module subroutine/function` 接口，测试子模块通过宿主关联访问原有私有类型和状态。实现移出后，原有可见性和调用签名保持不变；只有原来嵌在 `run_enks` 内部的 `test_repl_loc` 增加了过程参数，用于传入原内部生产例程。光解模块内部的插值测试改名为私有的 `test_interp_weights`。

本地GNU Fortran 11环境存在父模块私有过程的跨子模块链接问题。相关父模块保留私有的 `test_bind_*` 过程指针，初始化为原计算过程；测试通过这些绑定调用原例程，参数和计算保持不变。这些绑定不公开生产类型、数据或过程，编译器背景见[构建系统](docs/dev/构建系统.md)。

正常模型仅链接 `tests/numerics/test_fishpack_silam_impl.f90`，以保留风场初始化中的参考问题自检。其他测试子模块通过通用构建入口选择，不加入正常模型。

### 构建

从项目根目录执行以下命令，编译并链接全部测试子模块：

```bash
make -C build -f makefile.generic PROGRAM=silam_main SETUP=gnu
```

此命令生成 `bin/silam_main.gnu`，使用模型主程序检查所有测试实现的链接；它不会自动执行这些历史测试过程。构建需要支持 Fortran 2008 子模块的编译器。依赖生成器会先编译父模块，再编译相应测试子模块；`.mod`、`.smod` 和对象文件统一放入对象目录。

三个历史独立程序保留原文件名和构建名称：

```bash
make -C build -f makefile.generic PROGRAM=test_modules SETUP=gnu
make -C build -f makefile.generic PROGRAM=test_enkf SETUP=gnu
make -C build -f makefile.generic PROGRAM=test_perturb SETUP=gnu
```

对应源文件为 `tests/transport/test_modules.f90`、`tests/assimilation/test_enkf.f90`、`tests/assimilation/test_perturb.f90`。它们存在已确认的过时接口问题，后两个程序还缺少运行配置，不能视为已通过的测试。

### 运行与限制

测试过程继承原有输入、随机种子、状态修改、输出和停止行为。部分测试需要外部数据库、气象文件或已初始化的模型，部分测试需要交互输入或手工判断。`grids_geo.grid_tst` 和 `dispersion_models.exec_tests` 是空钩子；沉降曲线演示不带数值验收判据；光解速率测试中仍有未启用的计算调用。

运行时使用项目 `.tmp/` 下独立任务目录，避免覆盖输入和参考结果。完整过程清单、私有依赖和验证范围见[测试与调试](docs/dev/测试与调试.md)。

<a id="runtime-resources"></a>

## 运行资源与配置示例

`ini/` 根层保留24个公共资源文件：13个数据、映射或格式说明文件，以及11个
`standard_*_cocktails.ini` 混合物定义。`ini/eccodes/` 保留21个本地定义文件。
33个控制示例、排放源模板、输出和辅助配置按用途放在 `ini/examples/` 下。

公共资源仍使用原来的路径。`daemon/` 有自己的点源和输出配置，通过
`standard_setup_directory` 读取这里的公共资源，使用方法见
[toypoint说明](#toypoint)。

### 目录与示例索引

```text
ini/
├── *.dat、*.silam、pollen.materials、silja_nuclides.legend
├── standard_*_cocktails.ini
├── eccodes/definitions/       # 保持既有内部目录
└── examples/
    ├── pollen/               # 10个花粉控制、源和输出模板
    ├── transport/            # 11个共享输送控制和源模板
    ├── assimilation/         # 6个同化控制和协方差配置
    └── common/               # 6个共用输出、边界和历史系统配置
```

| 目录与用途 | 文件 |
|------------|------|
| 花粉控制 | [pollen.ctrl](ini/examples/pollen/pollen.ctrl)、[tst_pollen.ctrl](ini/examples/pollen/tst_pollen.ctrl)、[tst_olive.ctrl](ini/examples/pollen/tst_olive.ctrl)、[ragweed_mTh_2011.ctrl](ini/examples/pollen/ragweed_mTh_2011.ctrl) |
| 花粉源 | [src_pollen_birch.ini](ini/examples/pollen/src_pollen_birch.ini)、[src_pollen_birch_tst.ini](ini/examples/pollen/src_pollen_birch_tst.ini)、[src_pollen_grass.ini](ini/examples/pollen/src_pollen_grass.ini)、[src_pollen_olive.ini](ini/examples/pollen/src_pollen_olive.ini)、[ragweed_source.v6](ini/examples/pollen/ragweed_source.v6) |
| 花粉输出 | [output_config_pollen.ini](ini/examples/pollen/output_config_pollen.ini) |
| 共享输送控制 | [age_of_air.ctrl](ini/examples/transport/age_of_air.ctrl)、[tst.ctrl](ini/examples/transport/tst.ctrl)、[tst_adv.ctrl](ini/examples/transport/tst_adv.ctrl)、[tst_lagr.ctrl](ini/examples/transport/tst_lagr.ctrl)、[tst_TL_scav.ctrl](ini/examples/transport/tst_TL_scav.ctrl) |
| 共享输送源 | [src_area.tst](ini/examples/transport/src_area.tst)、[src_area.v3](ini/examples/transport/src_area.v3)、[src_new_air.as3](ini/examples/transport/src_new_air.as3)、[src_plumerise.v5](ini/examples/transport/src_plumerise.v5)、[src_point.v5](ini/examples/transport/src_point.v5)、[src_sea_salt_global.ini](ini/examples/transport/src_sea_salt_global.ini) |
| 同化控制 | [DA_iter.ctrl](ini/examples/assimilation/DA_iter.ctrl)、[DA_iter_birch.ctrl](ini/examples/assimilation/DA_iter_birch.ctrl)、[DA_ref.ctrl](ini/examples/assimilation/DA_ref.ctrl)、[da_enks.control](ini/examples/assimilation/da_enks.control)、[da_inversion.control](ini/examples/assimilation/da_inversion.control) |
| 同化协方差 | [cov_time_height.ini](ini/examples/assimilation/cov_time_height.ini) |
| 共用输出 | [output_config.ini](ini/examples/common/output_config.ini)、[output_config_glob.ini](ini/examples/common/output_config_glob.ini)、[output_config_tst.ini](ini/examples/common/output_config_tst.ini)、[output_config_tst_v5_4.ini](ini/examples/common/output_config_tst_v5_4.ini) |
| 边界与历史系统配置 | [boundary.ini](ini/examples/common/boundary.ini)、[standard_eulerian.setup](ini/examples/common/standard_eulerian.setup) |

### 公共资源索引

| 用途 | 文件 |
|------|------|
| 物质与核素 | [silam_chemicals_95_OC.dat](ini/silam_chemicals_95_OC.dat)、[silam_nuclides.dat](ini/silam_nuclides.dat) |
| 光学与OH气候态 | [optical_properties.dat](ini/optical_properties.dat)、[clim_oh_v3.dat](ini/clim_oh_v3.dat) |
| 时区 | [tzindex.dat](ini/tzindex.dat)、[tzindex_added_country_codes.dat](ini/tzindex_added_country_codes.dat) |
| 土地利用元数据 | [land_use_features_USGS_Eurasia.dat](ini/land_use_features_USGS_Eurasia.dat) |
| GRIB映射 | [grib_name_table.silam](ini/grib_name_table.silam)、[grib_name_table_mucape.silam](ini/grib_name_table_mucape.silam)、[grib_code_table_v5.silam](ini/grib_code_table_v5.silam) |
| NetCDF映射 | [netcdf_name_table.silam](ini/netcdf_name_table.silam) |
| 补充物质定义与格式说明 | [pollen.materials](ini/pollen.materials)、[silja_nuclides.legend](ini/silja_nuclides.legend) |
| 基础混合物 | [standard_aerosols_cocktails.ini](ini/standard_aerosols_cocktails.ini)、[standard_auxillary_cocktails.ini](ini/standard_auxillary_cocktails.ini) |
| 化学机制混合物 | [standard_chemistry_cocktails.ini](ini/standard_chemistry_cocktails.ini)、[standard_chemistry_cocktails_cbm4.ini](ini/standard_chemistry_cocktails_cbm4.ini)、[standard_chemistry_cocktails_cbm5.ini](ini/standard_chemistry_cocktails_cbm5.ini)、[standard_chemistry_cocktails_cbm7.ini](ini/standard_chemistry_cocktails_cbm7.ini) |
| SOA选项 | [standard_SOA_cocktails.ini](ini/standard_SOA_cocktails.ini)、[standard_SOAplus_cocktails.ini](ini/standard_SOAplus_cocktails.ini)、[standard_noSOA_cocktails.ini](ini/standard_noSOA_cocktails.ini) |
| 火灾与放射性混合物 | [standard_fires_cocktails.ini](ini/standard_fires_cocktails.ini)、[standard_radioactive_cocktails.ini](ini/standard_radioactive_cocktails.ini) |

`pollen.materials` 是单独的补充物质定义，现有仓库配置未直接引用它；
`silja_nuclides.legend` 只含核素文件格式说明。土地利用元数据也包含历史机器上的
外部影像路径，不表示影像已随仓库提供。

### 路径约定

- `STANDARD_SETUP` 内的 `^` 以 `standard_setup_directory` 为基准；未指定该项时，
  以控制文件所在目录为基准。普通相对路径仍需结合运行工作目录解释。
- 排放源内的 `^` 以源文件位置为基准。源模板、历史系统配置和未设置
  `standard_setup_directory` 的控制文件移入子目录后，原来指向 `ini/` 的引用使用
  `^../../`，保持原目标位置。
- 指向已搬迁模板的 `ini/<文件名>` 引用包含新的 `examples/<用途>/` 路径。
  历史机器路径的根目录和环境变量仍需使用者按实际输入配置。
- 两个 GRIB 名称表仍通过 `local_definition_path = ^eccodes/definitions` 加载本地定义。
  移动名称表时需要同步调整此路径；本轮保留名称表和 `eccodes/` 的原位置。

### 历史示例的使用边界

`examples/` 中的文件保留原有科学参数、版本差异、外部输入和占位变量，未逐个验证
能否直接运行。使用时先复制到独立运行目录，并核对以下条件：

| 示例或资源 | 需要核对的条件 |
|------------|----------------|
| 多份 `.ctrl` | 仍包含 `d:`、`e:` 等历史绝对路径，气象、植被及物候数据需另行提供 |
| `standard_eulerian.setup` | 引用未提供的 `silam_chemicals.dat` 和 `standard.cocktails`，属于历史配置 |
| `pollen.ctrl`、`tst_olive.ctrl`、`tst_lagr.ctrl`、`tst_TL_scav.ctrl` 等 | 部分配置同样引用 `silam_chemicals.dat`；不能直接认定与现有数据库等价 |
| `DA_iter.ctrl` | 需要外部 `cov_nondiag.ini`、`output_config_iter.ini` 等文件 |
| `DA_iter_birch.ctrl` | 需要外部 `cov_nondiag_std_div_100.ini`、`output_config_pollen_4dvar_iter.ini` 等文件 |
| `da_enks.control`、`da_inversion.control` | 需要填入环境变量或模板占位内容，并提供相应输入 |
| `ragweed_mTh_2011.ctrl` | 使用外部 `nonstandard_eulerian.setup` 等历史配置 |
| `src_sea_salt_global.ini` | 需要外部水体掩膜；`tst_TL_scav.ctrl` 还需要外部光解表及排放数据 |

这些缺失输入与历史兼容性问题沿用原状。目录整理不替换物质数据库、不转换控制格式，
也不补造外部输入。共享输送案例的通过不能代替花粉专属过程验证，验证层次见
[测试与调试](docs/dev/测试与调试.md)。

### 保留的差异版本

- 两个 birch 源文件的 `hsum_cutoff_t` 分别为276.65和266.65，测试版本仍单独保留。
- `grib_name_table_mucape.silam` 以0.33缩放MUCAPE来近似CAPE，并与默认表有其他映射差异。
- `tzindex_added_country_codes.dat` 带国家代码列；CBM与SOA混合物也各有机制或选项差异。
- 输出配置保留各自的变量、清单选择和时间平均设置。
- [shortName.def-bak](ini/eccodes/definitions/grib2/localConcepts/mcoop/shortName.def-bak)
  与现用文件内容不同，本轮保留，后续核实用途后再决定是否清理。

<a id="eccodes-definitions"></a>

### ecCodes 本地定义说明

`ini/eccodes/definitions/grib1/localConcepts/mcoop/` 的原始说明：

```text
Tweaked metcoop-grib_api-definitions_v5

shortName tweaked so far
```

<a id="toypoint"></a>

## 点源案例（daemon/）

本仓库的点源案例位于 `daemon/`，包含 `ERA_I-cut/` 气象输入、点源、输出和控制配置。以下保留上游独立案例的获取与使用说明；可执行文件名应以实际构建为准。

This is a simple point-source case for Silam model.
The case is made to complete within a few  seconds even at quite ancient computer.
ERA-Interim (ECMWF, https://www.ecmwf.int/en/forecasts/datasets/reanalysis-datasets/era-interim)
is used as a meteo driver for the case.

### Usage

1. If not yet done, get and compile compile SILAM (see
   https://github.com/fmidev/silam-model) to get thw model binary and
   supplementary data files.  Instructions below assume that
   "/path/to/silam-model" is the location of a working copy of the silam-model
   repo.

2. Clone the present directory to some other path:

  `$ git clone https://github.com/fmidev/silam-toypoint`

  `$ cd  silam-toypoint`

3. Make sure that `standard_setup_directory` parameter in the `toypoint_mpi.control` file points to
/path/to/silam-model/ini directory. The path can be absolute, relative or a symlink.

Example for the symlink:

`$ ln -sfn /path/to/silam-model/ini ini`

3. Then feeding a .control file as a parameter to Silam should run the case. E.g.

`$ /path/to/silam-model/bin/silam_v5_8pub toypoint_mpi.control`

should produce you a nice simulation of a puff dispersion.

4. The resulting .nc file can be visualised in some visualisation software, such as
GrADS, panoply, ncview etc...

5. Feel free to modify source height, time, release duration etc.
Please refer to (a bit outdated) user guide  http://silam.fmi.fi/ -> Documents

6. Enjoy!
