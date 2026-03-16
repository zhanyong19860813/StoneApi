CREATE TABLE [dbo].[vben_form_schema](
	[id] [uniqueidentifier] NOT NULL,
	[entitylistid] [uniqueidentifier] NOT NULL,
	[form_code] [nvarchar](100) NOT NULL,
	[form_name] [nvarchar](200) NULL,
	[cols] [int] NULL,
	[remark] [nvarchar](500) NULL,
	[created_at] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_form_schema] ADD  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[vben_form_schema] ADD  DEFAULT ((4)) FOR [cols]
GO

ALTER TABLE [dbo].[vben_form_schema] ADD  DEFAULT (getdate()) FOR [created_at]
GO