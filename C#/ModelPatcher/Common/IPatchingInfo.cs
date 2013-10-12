namespace EFGuidIdentityPatcher.Common
{
    public interface IPatchingInfo
    {
        string ConnectionString { get; }
        string XmlFile { get; }
    }
}