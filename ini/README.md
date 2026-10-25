# SILAM 运行资源与配置示例

`ini/` 根层保留24个公共资源文件：13个数据、映射或格式说明文件，以及11个
`standard_*_cocktails.ini` 混合物定义。`eccodes/` 保留22个本地定义文件。
33个控制示例、排放源模板、输出和辅助配置按用途放在 `examples/` 下；本索引另计。

公共资源仍使用原来的路径。`silam-toypoint/` 有自己的点源和输出配置，通过
`standard_setup_directory` 读取这里的公共资源，使用方法见
[toypoint说明](../silam-toypoint/README.md)。

## 目录与示例索引

```text
ini/
├── README.md
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
| 花粉控制 | [pollen.ctrl](examples/pollen/pollen.ctrl)、[tst_pollen.ctrl](examples/pollen/tst_pollen.ctrl)、[tst_olive.ctrl](examples/pollen/tst_olive.ctrl)、[ragweed_mTh_2011.ctrl](examples/pollen/ragweed_mTh_2011.ctrl) |
| 花粉源 | [src_pollen_birch.ini](examples/pollen/src_pollen_birch.ini)、[src_pollen_birch_tst.ini](examples/pollen/src_pollen_birch_tst.ini)、[src_pollen_grass.ini](examples/pollen/src_pollen_grass.ini)、[src_pollen_olive.ini](examples/pollen/src_pollen_olive.ini)、[ragweed_source.v6](examples/pollen/ragweed_source.v6) |
| 花粉输出 | [output_config_pollen.ini](examples/pollen/output_config_pollen.ini) |
| 共享输送控制 | [age_of_air.ctrl](examples/transport/age_of_air.ctrl)、[tst.ctrl](examples/transport/tst.ctrl)、[tst_adv.ctrl](examples/transport/tst_adv.ctrl)、[tst_lagr.ctrl](examples/transport/tst_lagr.ctrl)、[tst_TL_scav.ctrl](examples/transport/tst_TL_scav.ctrl) |
| 共享输送源 | [src_area.tst](examples/transport/src_area.tst)、[src_area.v3](examples/transport/src_area.v3)、[src_new_air.as3](examples/transport/src_new_air.as3)、[src_plumerise.v5](examples/transport/src_plumerise.v5)、[src_point.v5](examples/transport/src_point.v5)、[src_sea_salt_global.ini](examples/transport/src_sea_salt_global.ini) |
| 同化控制 | [DA_iter.ctrl](examples/assimilation/DA_iter.ctrl)、[DA_iter_birch.ctrl](examples/assimilation/DA_iter_birch.ctrl)、[DA_ref.ctrl](examples/assimilation/DA_ref.ctrl)、[da_enks.control](examples/assimilation/da_enks.control)、[da_inversion.control](examples/assimilation/da_inversion.control) |
| 同化协方差 | [cov_time_height.ini](examples/assimilation/cov_time_height.ini) |
| 共用输出 | [output_config.ini](examples/common/output_config.ini)、[output_config_glob.ini](examples/common/output_config_glob.ini)、[output_config_tst.ini](examples/common/output_config_tst.ini)、[output_config_tst_v5_4.ini](examples/common/output_config_tst_v5_4.ini) |
| 边界与历史系统配置 | [boundary.ini](examples/common/boundary.ini)、[standard_eulerian.setup](examples/common/standard_eulerian.setup) |

## 公共资源索引

| 用途 | 文件 |
|------|------|
| 物质与核素 | [silam_chemicals_95_OC.dat](silam_chemicals_95_OC.dat)、[silam_nuclides.dat](silam_nuclides.dat) |
| 光学与OH气候态 | [optical_properties.dat](optical_properties.dat)、[clim_oh_v3.dat](clim_oh_v3.dat) |
| 时区 | [tzindex.dat](tzindex.dat)、[tzindex_added_country_codes.dat](tzindex_added_country_codes.dat) |
| 土地利用元数据 | [land_use_features_USGS_Eurasia.dat](land_use_features_USGS_Eurasia.dat) |
| GRIB映射 | [grib_name_table.silam](grib_name_table.silam)、[grib_name_table_mucape.silam](grib_name_table_mucape.silam)、[grib_code_table_v5.silam](grib_code_table_v5.silam) |
| NetCDF映射 | [netcdf_name_table.silam](netcdf_name_table.silam) |
| 补充物质定义与格式说明 | [pollen.materials](pollen.materials)、[silja_nuclides.legend](silja_nuclides.legend) |
| 基础混合物 | [standard_aerosols_cocktails.ini](standard_aerosols_cocktails.ini)、[standard_auxillary_cocktails.ini](standard_auxillary_cocktails.ini) |
| 化学机制混合物 | [standard_chemistry_cocktails.ini](standard_chemistry_cocktails.ini)、[standard_chemistry_cocktails_cbm4.ini](standard_chemistry_cocktails_cbm4.ini)、[standard_chemistry_cocktails_cbm5.ini](standard_chemistry_cocktails_cbm5.ini)、[standard_chemistry_cocktails_cbm7.ini](standard_chemistry_cocktails_cbm7.ini) |
| SOA选项 | [standard_SOA_cocktails.ini](standard_SOA_cocktails.ini)、[standard_SOAplus_cocktails.ini](standard_SOAplus_cocktails.ini)、[standard_noSOA_cocktails.ini](standard_noSOA_cocktails.ini) |
| 火灾与放射性混合物 | [standard_fires_cocktails.ini](standard_fires_cocktails.ini)、[standard_radioactive_cocktails.ini](standard_radioactive_cocktails.ini) |

`pollen.materials` 是单独的补充物质定义，现有仓库配置未直接引用它；
`silja_nuclides.legend` 只含核素文件格式说明。土地利用元数据也包含历史机器上的
外部影像路径，不表示影像已随仓库提供。

## 路径约定

- `STANDARD_SETUP` 内的 `^` 以 `standard_setup_directory` 为基准；未指定该项时，
  以控制文件所在目录为基准。普通相对路径仍需结合运行工作目录解释。
- 排放源内的 `^` 以源文件位置为基准。源模板、历史系统配置和未设置
  `standard_setup_directory` 的控制文件移入子目录后，原来指向 `ini/` 的引用使用
  `^../../`，保持原目标位置。
- 指向已搬迁模板的 `ini/<文件名>` 引用包含新的 `examples/<用途>/` 路径。
  历史机器路径的根目录和环境变量仍需使用者按实际输入配置。
- 两个 GRIB 名称表仍通过 `local_definition_path = ^eccodes/definitions` 加载本地定义。
  移动名称表时需要同步调整此路径；本轮保留名称表和 `eccodes/` 的原位置。

## 历史示例的使用边界

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
[测试与调试](../doc/dev/测试与调试.md)。

## 保留的差异版本

- 两个 birch 源文件的 `hsum_cutoff_t` 分别为276.65和266.65，测试版本仍单独保留。
- `grib_name_table_mucape.silam` 以0.33缩放MUCAPE来近似CAPE，并与默认表有其他映射差异。
- `tzindex_added_country_codes.dat` 带国家代码列；CBM与SOA混合物也各有机制或选项差异。
- 输出配置保留各自的变量、清单选择和时间平均设置。
- [shortName.def-bak](eccodes/definitions/grib2/localConcepts/mcoop/shortName.def-bak)
  与现用文件内容不同，本轮保留，后续核实用途后再决定是否清理。
