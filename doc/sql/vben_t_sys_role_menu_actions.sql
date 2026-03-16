
CREATE TABLE [dbo].[vben_t_sys_role_menu_actions](
	[id] [uniqueidentifier] NOT NULL,
	[role_id] [uniqueidentifier] NOT NULL,
	[menu_action_id] [uniqueidentifier] NOT NULL,
	[menu_id] [uniqueidentifier] NOT NULL,
	[status] [int] NULL,
	[add_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_t_sys_role_menu_actions] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_t_sys_role_menu_actions] ADD  DEFAULT ((1)) FOR [status]
GO

ALTER TABLE [dbo].[vben_t_sys_role_menu_actions] ADD  DEFAULT (getdate()) FOR [add_time]
GO


