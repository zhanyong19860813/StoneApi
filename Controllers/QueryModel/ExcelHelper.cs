using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using System.Collections.Generic;
using System.Data;

public static class ExcelHelper
{
    public static byte[] ExportDataTableToExcel(DataTable dt)
    {
        IWorkbook workbook = new XSSFWorkbook();
        ISheet sheet = workbook.CreateSheet("Sheet1");

        // 表头
        IRow header = sheet.CreateRow(0);
        for (int i = 0; i < dt.Columns.Count; i++)
        {
            header.CreateCell(i).SetCellValue(dt.Columns[i].ColumnName);
        }

        // 数据
        for (int i = 0; i < dt.Rows.Count; i++)
        {
            IRow row = sheet.CreateRow(i + 1);
            for (int j = 0; j < dt.Columns.Count; j++)
            {
                row.CreateCell(j).SetCellValue(dt.Rows[i][j]?.ToString());
            }
        }

        // 自动列宽
        for (int i = 0; i < dt.Columns.Count; i++)
        {
            sheet.AutoSizeColumn(i);
        }

        using var ms = new MemoryStream();
        workbook.Write(ms);
        return ms.ToArray();
    }
}