CREATE TABLE [dbo].[vben_menus_new](
	[id] [uniqueidentifier] NOT NULL,
	[name] [nvarchar](255) NOT NULL,
	[path] [nvarchar](255) NOT NULL,
	[component] [nvarchar](255) NOT NULL,
	[meta] [nvarchar](500) NULL,
	[parent_id] [uniqueidentifier] NULL,
	[status] [int] NULL,
	[type] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_menus_new] ADD  CONSTRAINT [DF_vben_menus_new_id]  DEFAULT (newid()) FOR [id]
GO
