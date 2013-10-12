using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using GuidIdentityPatcher.Common;

namespace GetDefaultValues
{
    public class DbContext
    {
        private readonly string _query;
        private readonly string _connectionString;

        public DbContext(IPatchingInfo patchingInfo)
        {
            if (patchingInfo == null)
                throw new ArgumentNullException("patchingInfo");

            _connectionString = patchingInfo.ConnectionString;
            _query = "SELECT object_name([COL].[id]) AS [Table],[COL].[name] AS [Column],[COM].[text] AS [DefaultValue] " +
                     "FROM syscolumns AS [COL] INNER JOIN syscomments AS [COM] ON [COL].[cdefault] = [COM].[id]" +
                     "WHERE [COM].[text] LIKE '%NEWSEQUENTIALID%'";
        }

        public List<TableInfo> GetDefualtValues()
        {
            var list = new List<TableInfo>();
            using (var con = new SqlConnection(_connectionString))
            {
                con.Open();
                var reader = new SqlCommand(_query, con).ExecuteReader();
                while (reader.Read())
                {
                    list.Add(new TableInfo
                                 {
                                     Table = reader["Table"] as string,
                                     Column = reader["Column"] as string,
                                     DefaultValue = reader["DefaultValue"] as string
                                 });
                }
            }
            return list;
        }
    }
}
