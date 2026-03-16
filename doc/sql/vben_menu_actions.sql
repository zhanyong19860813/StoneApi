CREATE TABLE [dbo].[vben_menu_actions](
	[id] [uniqueidentifier] NOT NULL,
	[menu_id] [uniqueidentifier] NOT NULL,
	[action_key] [nvarchar](50) NOT NULL,
	[label] [nvarchar](50) NOT NULL,
	[button_type] [nvarchar](20) NULL,
	[action] [nvarchar](100) NOT NULL,
	[confirm_text] [nvarchar](200) NULL,
	[sort] [int] NULL,
	[status] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_menu_actions] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_menu_actions] ADD  DEFAULT ((0)) FOR [sort]
GO

ALTER TABLE [dbo].[vben_menu_actions] ADD  DEFAULT ((1)) FOR [status]
GO
