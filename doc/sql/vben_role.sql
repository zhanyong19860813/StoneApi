
CREATE TABLE [dbo].[vben_role](
	[id] [uniqueidentifier] NOT NULL,
	[name] [nvarchar](100) NULL,
	[parent_id] [uniqueidentifier] NULL,
	[datatype] [nvarchar](10) NULL,
	[createtime] [datetime] NULL,
	[createUser] [nvarchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vben_role] ADD  DEFAULT (getdate()) FOR [createtime]
GO
