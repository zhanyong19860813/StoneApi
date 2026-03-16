CREATE TABLE [dbo].[vben_t_sys_role_menus](
	[id] [uniqueidentifier] NOT NULL,
	[role_id] [uniqueidentifier] NULL,
	[menus_id] [uniqueidentifier] NULL,
	[bar_items] [varchar](350) NULL,
	[operate_range_type] [varchar](200) NULL,
	[dept_range] [varchar](4000) NULL,
	[define_condition] [varchar](1000) NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_t_sys_role_menus] ADD  DEFAULT (newid()) FOR [id]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'角色' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_role_menus', @level2type=N'COLUMN',@level2name=N'role_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'功能' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_role_menus', @level2type=N'COLUMN',@level2name=N'menus_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'按钮' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_role_menus', @level2type=N'COLUMN',@level2name=N'bar_items'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'数据范围' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_role_menus', @level2type=N'COLUMN',@level2name=N'operate_range_type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'部门' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_role_menus', @level2type=N'COLUMN',@level2name=N'dept_range'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'自定义条件' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_role_menus', @level2type=N'COLUMN',@level2name=N'define_condition'
GO