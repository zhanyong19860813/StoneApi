declare module 'mssql' {
  export interface Request {
    input(name: string, type: unknown, value: unknown): Request;
    query(query: string): Promise<{ recordset: any[] }>;
  }

  export interface ConnectionPool {
    connected: boolean;
    request(): Request;
    query(query: string): Promise<{ recordset: any[] }>;
  }

  export type config = Record<string, unknown>;

  export interface SqlStatic {
    connect(cfg: string | config): Promise<ConnectionPool>;
    NVarChar(n?: number): unknown;
    Int: unknown;
  }

  const sql: SqlStatic;
  export default sql;
}
