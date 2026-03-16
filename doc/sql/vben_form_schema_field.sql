CREATE TABLE [dbo].[vben_form_schema_field](
	[id] [uniqueidentifier] NOT NULL,
	[entitylistid] [uniqueidentifier] NOT NULL,
	[form_schema_id] [uniqueidentifier] NOT NULL,
	[field_name] [nvarchar](100) NOT NULL,
	[label] [nvarchar](200) NULL,
	[component] [nvarchar](50) NULL,
	[component_props] [nvarchar](max) NULL,
	[rules] [nvarchar](max) NULL,
	[default_value] [nvarchar](500) NULL,
	[sort] [int] NULL,
	[cols] [int] NULL,
	[visible] [bit] NULL,
	[required] [bit] NULL,
	[remark] [nvarchar](500) NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_form_schema_field] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_form_schema_field] ADD  DEFAULT ((0)) FOR [sort]
GO

ALTER TABLE [dbo].[vben_form_schema_field] ADD  DEFAULT ((1)) FOR [cols]
GO

ALTER TABLE [dbo].[vben_form_schema_field] ADD  DEFAULT ((1)) FOR [visible]
GO

ALTER TABLE [dbo].[vben_form_schema_field] ADD  DEFAULT ((0)) FOR [required]
GO

ALTER TABLE [dbo].[vben_form_schema_field] ADD  DEFAULT (getdate()) FOR [created_at]
GO
