# SILAM测试代码

测试按 `src/` 的功能目录组织。每个原模块的测试实现放在同目录名下的 `test_<模块名>_impl.f90` 中，文件名与 Fortran 子模块名一致。当前有29个测试子模块和三个历史独立测试程序。

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

本地GNU Fortran 11环境存在父模块私有过程的跨子模块链接问题。相关父模块保留私有的 `test_bind_*` 过程指针，初始化为原计算过程；测试通过这些绑定调用原例程，参数和计算保持不变。这些绑定不公开生产类型、数据或过程，编译器背景见[构建系统](../doc/dev/构建系统.md)。

正常模型仅链接 `numerics/test_fishpack_silam_impl.f90`，以保留风场初始化中的参考问题自检。其他测试子模块通过通用构建入口选择，不加入正常模型。

## 构建

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

对应源文件为 `transport/test_modules.f90`、`assimilation/test_enkf.f90`、`assimilation/test_perturb.f90`。它们存在已确认的过时接口问题，后两个程序还缺少运行配置，不能视为已通过的测试。

## 运行与限制

测试过程继承原有输入、随机种子、状态修改、输出和停止行为。部分测试需要外部数据库、气象文件或已初始化的模型，部分测试需要交互输入或手工判断。`grids_geo.grid_tst` 和 `dispersion_models.exec_tests` 是空钩子；沉降曲线演示不带数值验收判据；光解速率测试中仍有未启用的计算调用。

运行时使用项目 `.tmp/` 下独立任务目录，避免覆盖输入和参考结果。完整过程清单、私有依赖和验证范围见[测试与调试](../doc/dev/测试与调试.md)。
