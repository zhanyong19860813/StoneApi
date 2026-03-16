
CREATE TABLE [dbo].[vben_entity_list](
	[id] [uniqueidentifier] NOT NULL,
	[entity_name] [varchar](50) NOT NULL,
	[title] [varchar](100) NULL,
	[tableName] [varchar](100) NULL,
	[primaryKey] [varchar](50) NULL,
	[deleteEntityName] [varchar](100) NULL,
	[defaultSchema] [varchar](200) NULL,
	[status] [int] NULL,
	[created_at] [datetime] NULL,
	[updated_at] [datetime] NULL,
	[actionModule] [nvarchar](1000) NULL,
	[sortFieldName] [nvarchar](50) NULL,
	[sortType] [nvarchar](10) NULL,
	[saveEntityName] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[entity_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_entity_list] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_entity_list] ADD  DEFAULT ('FID') FOR [primaryKey]
GO

ALTER TABLE [dbo].[vben_entity_list] ADD  DEFAULT ((1)) FOR [status]
GO

ALTER TABLE [dbo].[vben_entity_list] ADD  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [dbo].[vben_entity_list] ADD  DEFAULT ('desc') FOR [sortType]
GO
