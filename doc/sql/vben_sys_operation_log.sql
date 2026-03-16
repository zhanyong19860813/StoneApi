-- 系统操作日志表
-- 记录：菜单访问、按钮点击、查询/保存/删除的 SQL
CREATE TABLE [dbo].[vben_sys_operation_log](
    [id] [uniqueidentifier] NOT NULL DEFAULT NEWID(),
    [user_id] [nvarchar](50) NULL,
    [user_name] [nvarchar](100) NULL,
    [action_type] [nvarchar](20) NOT NULL,
    [target] [nvarchar](200) NULL,
    [description] [nvarchar](500) NULL,
    [sql_text] [nvarchar](max) NULL,
    [request_params] [nvarchar](max) NULL,
    [endpoint] [nvarchar](200) NULL,
    [ip] [nvarchar](50) NULL,
    [created_at] [datetime] NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_vben_sys_operation_log] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_vben_sys_operation_log_created_at] ON [dbo].[vben_sys_operation_log]([created_at] DESC);
GO
CREATE NONCLUSTERED INDEX [IX_vben_sys_operation_log_user_id] ON [dbo].[vben_sys_operation_log]([user_id]);
GO
CREATE NONCLUSTERED INDEX [IX_vben_sys_operation_log_action_type] ON [dbo].[vben_sys_operation_log]([action_type]);
GO
