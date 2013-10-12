using System;

namespace EFGuidIdentityPatcher.Common
{
    public class PatchingInfo : IPatchingInfo
    {
        private readonly string _connectionString;
        private readonly string _xmlFile;

        public string ConnectionString
        {
            get { return _connectionString; }
        }

        public string XmlFile
        {
            get { return _xmlFile; }
        }

        public PatchingInfo(string connectionString, string xmlFile)
        {
            if (connectionString == null)
                throw new ArgumentNullException("connectionString");
            if (xmlFile == null)
                throw new ArgumentNullException("xmlFile");

            _connectionString = connectionString;
            _xmlFile = xmlFile;
        }
    }
}
