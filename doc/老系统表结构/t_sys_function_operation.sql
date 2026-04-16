USE [SJHRsalarySystemDb]
GO

/****** Object:  Table [dbo].[t_sys_function_operation]    Script Date: 2026/4/2 10:28:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[t_sys_function_operation](
	[id] [uniqueidentifier] NOT NULL,
	[name] [varchar](150) NOT NULL,
	[caption] [varchar](150) NOT NULL,
	[action] [varchar](150) NULL,
	[icon_css] [varchar](50) NULL,
	[place] [varchar](20) NULL,
	[is_list_page] [varchar](1) NULL,
	[custom_defing_script] [varchar](2500) NULL,
	[is_common] [varchar](1) NULL,
	[sort] [smallint] NOT NULL,
	[function_id] [uniqueidentifier] NULL,
	[description] [varchar](500) NULL,
	[add_user] [uniqueidentifier] NULL,
	[add_time] [datetime] NULL,
 CONSTRAINT [PK_t_sys_function_operation] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[t_sys_function_operation] ADD  CONSTRAINT [DF_t_sys_function_operation_id]  DEFAULT (newid()) FOR [id]
GO

ALTER TABLE [dbo].[t_sys_function_operation]  WITH CHECK ADD  CONSTRAINT [FK_t_sys_function_operation_t_sys_function] FOREIGN KEY([function_id])
REFERENCES [dbo].[t_sys_function] ([id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[t_sys_function_operation] CHECK CONSTRAINT [FK_t_sys_function_operation_t_sys_function]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'名字' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function_operation', @level2type=N'COLUMN',@level2name=N'name'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'显示名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function_operation', @level2type=N'COLUMN',@level2name=N'caption'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'执行方法' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function_operation', @level2type=N'COLUMN',@level2name=N'action'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'自定义脚本' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function_operation', @level2type=N'COLUMN',@level2name=N'custom_defing_script'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'功能操作' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N't_sys_function_operation'
GO


