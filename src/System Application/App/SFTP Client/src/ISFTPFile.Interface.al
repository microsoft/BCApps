namespace System.SFTPClient;

interface "ISFTP File"
{
    Access = Public;
    procedure MoveTo(Destination: Text): Boolean
    procedure Name(): Text
    procedure FullName(): Text
    procedure IsDirectory(): Boolean
    procedure Length(): BigInteger
}