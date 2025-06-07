namespace System.SFTPClient;

enum 50100 "SFTP Exception Type"
{
    Extensible = false;
    Access = Public;

    value(0; None)
    {
        Caption = 'No Exception';
    }
    value(1; "Generic Exception")
    {
        Caption = 'Generic Exception';
    }
    value(2; "Socket Exception")
    {
        Caption = 'Socket Exception';
    }
    value(3; "Invalid Operation Exception")
    {
        Caption = 'Invalid Operation Exception';
    }
    value(4; "SSH Connection Exception")
    {
        Caption = 'SSH Connection Exception';
    }
    value(5; "SSH Authentication Exception")
    {
        Caption = 'SSH Authentication Exception';
    }
    value(6; "SFTP Path Not Found Exception")
    {
        Caption = 'SFTP Path Not Found Exception';
    }
}