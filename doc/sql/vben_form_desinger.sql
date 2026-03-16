-- 表单设计器配置表
-- 存储表单设计器生成的 schema，供列表设计器按钮（新增/编辑等）弹出表单时使用
-- 与 vben_entitylist_desinger 结构对齐，便于统一管理

CREATE TABLE [dbo].[vben_form_desinger](
	[id] [uniqueidentifier] NOT NULL,
	[code] [nvarchar](50) NOT NULL,
	[title] [nvarchar](200) NULL,
	[schema_json] [nvarchar](max) NOT NULL,
	[list_code] [nvarchar](50) NULL,
	[created_at] [datetime] NULL,
	[updated_at] [datetime] NULL,
PRIMARY KEY CLUSTERED ([id] ASC)
)
GO

ALTER TABLE [dbo].[vben_form_desinger] ADD DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [dbo].[vben_form_desinger] ADD DEFAULT (getdate()) FOR [created_at]
GO

-- code 唯一索引，列表设计器通过 code 引用表单
CREATE UNIQUE NONCLUSTERED INDEX [IX_vben_form_desinger_code] ON [dbo].[vben_form_desinger]([code] ASC)
GO
