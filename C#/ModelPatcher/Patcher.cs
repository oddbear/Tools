using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;
using System.IO;
using EFGuidIdentityPatcher.Common;

namespace GetDefaultValues
{
    public class Patcher
    {
        private readonly string _xmlFile;
        private readonly List<TableInfo> _tableInfo;

        public Patcher(IPatchingInfo patchingInfo, List<TableInfo> tableInfo)
        {
            if (patchingInfo == null)
                throw new ArgumentNullException("patchingInfo");
            if (tableInfo == null)
                throw new ArgumentNullException("tableInfo");

            _xmlFile = patchingInfo.XmlFile;
            _tableInfo = tableInfo;
        }

        private void PatchElements(XDocument xDoc, string nameSpace, XAttribute attributeToAdd)
        {
            if (xDoc == null)
                throw new ArgumentNullException("xDoc");

            var reader = xDoc.CreateReader();
            if(reader == null)
                throw new XmlException("No Reader.");

            var nsM = new XmlNamespaceManager(reader.NameTable);
            nsM.AddNamespace("ns", nameSpace);

            var elements = (xDoc.XPathEvaluate("//ns:EntityType", nsM) as System.Collections.IEnumerable)
                .Cast<XElement>()
                .Join(_tableInfo.Select(t => t.Table).Distinct(), x => x.Attribute("Name").Value.ToUpper(), y => y.ToUpper(), (x, y) => x)
                ;
            foreach (var element in elements)
            {
                var columns = _tableInfo
                    .Where(t => t.Table.ToUpper() == element.Attribute("Name").Value.ToUpper())
                    .Where(t => t.DefaultValue.ToUpper().Contains("NEWSEQUENTIALID"))
                    .Select(t => t.Column);
                foreach (var column in columns)
                {
                    var name = XName.Get("Property", nameSpace);
                    var elementToPatch = element
                        .Descendants(name)
                        .Single(e => e.Attribute("Name").Value.ToUpper() == column.ToUpper());
                    elementToPatch.Add(attributeToAdd);
                }
            }
        }

        private void PatchFile(XDocument xDoc)
        {
            PatchElements(xDoc, "http://schemas.microsoft.com/ado/2009/02/edm/ssdl", new XAttribute("StoreGeneratedPattern", "Identity"));
            PatchElements(xDoc, "http://schemas.microsoft.com/ado/2008/09/edm", new XAttribute(XName.Get("StoreGeneratedPattern", "http://schemas.microsoft.com/ado/2009/02/edm/annotation"), "Identity"));
        }

        public bool Patch()
        {
            try
            {
                var directoryName = Path.GetDirectoryName(_xmlFile);

                if(directoryName == null)
                    throw new NullReferenceException("directoryName");

                var backupFile = Path.Combine(directoryName,
                                            string.Format("{0}_backup{1}{2}", Path.GetFileNameWithoutExtension(_xmlFile), DateTime.Now.ToString("yyyyMMdd_HHmmss"), Path.GetExtension(_xmlFile)));

                if(!File.Exists(_xmlFile))
                    throw new FileNotFoundException(_xmlFile);

                var xDoc = XDocument.Load(_xmlFile);

                PatchFile(xDoc);

                //File.Copy(_xmlFile, backupFile, true);
                xDoc.Save(backupFile);

                return true;
            }
            catch (InvalidOperationException ex)
            {
                if (ex.Message == "Duplicate attribute.")
                    Console.WriteLine("Enten allerede patcha, ellers har noen tukla med den!");
                return false;
            }
        }
    }
}
