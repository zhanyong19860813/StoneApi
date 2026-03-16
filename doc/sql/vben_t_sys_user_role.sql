
CREATE TABLE [dbo].[vben_t_sys_user_role](
	[id] [uniqueidentifier] NOT NULL,
	[user_id] [uniqueidentifier] NULL,
	[role_id] [uniqueidentifier] NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_t_sys_user_role] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_t_sys_user_role] ADD  CONSTRAINT [DF_vben_t_sys_user_role_add_time]  DEFAULT (getdate()) FOR [add_time]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'用户' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user_role', @level2type=N'COLUMN',@level2name=N'user_id'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'角色' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'vben_t_sys_user_role', @level2type=N'COLUMN',@level2name=N'role_id'
GO
