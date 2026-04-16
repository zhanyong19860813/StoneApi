USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[t_sys_function]    Script Date: 2026/4/2 10:03:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_sys_function](
	[id] [uniqueidentifier] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[code] [varchar](50) NULL,
	[parent_id] [uniqueidentifier] NULL,
	[entity_name] [varchar](250) NULL,
	[page] [varchar](250) NULL,
	[master_entity_name] [varchar](150) NULL,
	[condition] [varchar](500) NULL,
	[querystring] [varchar](200) NULL,
	[url] [varchar](500) NULL,
	[icon_css] [varchar](100) NULL,
	[icon_path] [varchar](100) NULL,
	[list_self_script] [varchar](2500) NULL,
	[path] [varchar](150) NULL,
	[type] [smallint] NULL,
	[sort] [smallint] NULL,
	[is_menu] [char](1) NULL,
	[is_mode] [int] NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
 CONSTRAINT [PK_t_sys_function] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[t_sys_function] ADD  CONSTRAINT [DF_t_sys_function_id]  DEFAULT (newid()) FOR [id]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'功能名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'编码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'code'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'父级菜单' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'parent_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'实体' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'entity_name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'功能页面' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'page'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'主从实体' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'master_entity_name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'图标样式' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'icon_css'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'图标地址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'icon_path'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'列表脚本' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'list_self_script'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'层次路径' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function', @level2type=N'COLUMN',@level2name=N'path'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'功能表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function'
GO


