
CREATE TABLE [dbo].[vben_t_sys_user](
	[id] [uniqueidentifier] NOT NULL,
	[username] [varchar](100) NOT NULL,
	[password] [varchar](100) NOT NULL,
	[employee_id] [varchar](50) NULL,
	[customer_no] [varchar](50) NULL,
	[name] [varchar](50) NULL,
	[effect_date] [date] NULL,
	[expire_date] [date] NULL,
	[status] [smallint] NULL,
	[user_type] [smallint] NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
	[lock_state] [smallint] NULL,
	[unlock_time] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_t_sys_user] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_t_sys_user] ADD  DEFAULT ((1)) FOR [user_type]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'用户名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'username'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'密码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'password'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'所属员工' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'employee_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'生效日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'effect_date'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'失效日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'expire_date'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'状态[0正常,1暂停,2停用]' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'status'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'用户类型（1，内部，0外部)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user', @level2type=N'COLUMN',@level2name=N'user_type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'用户表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user'
GO


