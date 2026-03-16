CREATE TABLE [dbo].[vben_entity_column](
	[id] [uniqueidentifier] NOT NULL,
	[entity_list_id] [uniqueidentifier] NOT NULL,
	[field] [varchar](50) NOT NULL,
	[title] [varchar](100) NULL,
	[used_in_list] [bit] NULL,
	[used_in_form] [bit] NULL,
	[column_type] [varchar](20) NULL,
	[width] [int] NULL,
	[sortable] [bit] NULL,
	[list_order] [int] NULL,
	[form_component] [varchar](50) NULL,
	[form_order] [int] NULL,
	[status] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_entity_column] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_entity_column] ADD  DEFAULT ((1)) FOR [used_in_list]
GO

ALTER TABLE [dbo].[vben_entity_column] ADD  DEFAULT ((0)) FOR [used_in_form]
GO

ALTER TABLE [dbo].[vben_entity_column] ADD  DEFAULT ((1)) FOR [status]
GO


