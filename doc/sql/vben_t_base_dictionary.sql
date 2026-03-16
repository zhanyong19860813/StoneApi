-- 数据字典分类表（图片左边的树）
CREATE TABLE [dbo].[vben_t_base_dictionary](
	[id] [uniqueidentifier] NOT NULL DEFAULT NEWID(),
	[name] [varchar](50) NULL,
	[code] [varchar](50) NULL,
	[data_type] [varchar](20) NULL,
	[description] [varchar](500) NULL,
	[parent_id] [uniqueidentifier] NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
	[sort] [int] NULL,
 CONSTRAINT [PK_vben_t_base_dictionary] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO

-- 数据字典明细表（图片右边的列表）
CREATE TABLE [dbo].[vben_t_base_dictionary_detail](
	[id] [uniqueidentifier] NOT NULL DEFAULT NEWID(),
	[dictionary_id] [uniqueidentifier] NULL,
	[name] [varchar](50) NULL,
	[value] [varchar](100) NULL,
	[description] [varchar](500) NULL,
	[sort] [smallint] NULL,
	[help_code] [varchar](200) NULL,
	[is_stop] [varchar](2) NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
 CONSTRAINT [PK_vben_t_base_dictionary_detail] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO

-- 添加字典菜单示例（表结构以 vben_menus_new 为例，parent_id 需改为你的「系统设置」等父菜单ID）
/*
INSERT INTO vben_menus_new (id, name, path, component, parent_id, type, meta)
VALUES (
  NEWID(),
  'Dictionary',
  '/Dictionary',
  'System/Dictionary/index',
  '你的系统设置父菜单ID',  -- 如 Sys 的 id
  'menu',
  '{"title":"字典设置","icon":"mdi:book-alphabet"}'
);
*/
