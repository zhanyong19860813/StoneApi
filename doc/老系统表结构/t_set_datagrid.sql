USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[t_set_datagrid]    Script Date: 2026/4/2 10:23:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_set_datagrid](
	[id] [uniqueidentifier] NOT NULL,
	[header] [varchar](100) NULL,
	[caption] [varchar](100) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[data_type] [varchar](50) NOT NULL,
	[editor] [varchar](200) NULL,
	[column_type] [varchar](50) NULL,
	[column_html] [nvarchar](500) NULL,
	[data_source_type] [varchar](20) NULL,
	[is_allow_edit] [varchar](1) NULL,
	[data_source] [varchar](500) NULL,
	[width] [int] NOT NULL,
	[data_formatter] [varchar](500) NULL,
	[sort] [int] NOT NULL,
	[is_key] [char](1) NULL,
	[is_visiable] [char](1) NULL,
	[is_fixed] [char](1) NULL,
	[is_resize] [char](1) NULL,
	[is_query] [char](1) NULL,
	[is_define_query] [char](1) NULL,
	[is_key_query] [char](1) NULL,
	[is_between] [char](1) NULL,
	[is_output] [char](1) NULL,
	[entity] [varchar](100) NOT NULL,
	[function_id] [uniqueidentifier] NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
	[is_total] [char](1) NULL,
 CONSTRAINT [PK_t_set_datagrid] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[t_set_datagrid] ADD  CONSTRAINT [DF_t_set_datagrid_allow_edit]  DEFAULT ('N') FOR [is_allow_edit]
GO

ALTER TABLE [dbo].[t_set_datagrid] ADD  CONSTRAINT [DF_t_set_datagrid_datasource]  DEFAULT ('N') FOR [data_source]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'表头名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'caption'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'字段名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据类型' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'data_type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'编辑控件' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'editor'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'列类型(indexcolumn|checkcolumn|checkboxcolumn|comboboxcolumn|treeselectcolumn)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'column_type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据来源类型:SQL,FIX,JSON,DIC' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'data_source_type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'允许编辑' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'is_allow_edit'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据源[data:"",url:""]' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'data_source'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'宽度' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'width'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据格式化方法' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'data_formatter'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'排序' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'sort'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否是关键字段' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'is_key'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否可视' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'is_visiable'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否支持查询' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'is_query'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'entity'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'所属功能模块' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid', @level2type=N'COLUMN',@level2name=N'function_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据窗口' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_set_datagrid'
GO


