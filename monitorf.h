extern unsigned char *vmfp;
extern unsigned short Reg_UCR;
extern unsigned short Reg_UDR;
extern unsigned short Reg_RSR;
extern unsigned short Reg_TSR;
extern void printChar(unsigned char pchr, unsigned char pmove);
extern void printText(unsigned char *msg);
extern void runCmd(void);

typedef struct
{
    unsigned short       firsts;         // Logical block address of the first sector of the FAT partition on the device
    unsigned short       fat;            // Logical block address of the FAT
    unsigned short       root;           // Logical block address of the root directory
    unsigned short       data;           // Logical block address of the data section of the device.
    unsigned short        maxroot;        // The maximum number of entries in the root directory.
    unsigned short       maxcls;         // The maximum number of clusters in the partition.
    unsigned short     RootEntiesCount;  // Num Root Entries
    unsigned short      numheads;       // Number of Heads
    unsigned short       sectorSize;     // The size of a sector in bytes
    unsigned short       secperfat;        // Sector per Fat
    unsigned short       secpertrack;        // Sector per Fat
    unsigned short       fatsize;        // The number of sectors in the FAT
    unsigned char     NumberOfFATs;     // Number of Fat's
    unsigned short        reserv;         // The number of copies of the FAT in the partition
    unsigned char        SecPerClus;     // The number of sectors per cluster in the data region
    unsigned char        type;           // The file system type of the partition (FAT12, FAT16 or FAT16)
    unsigned char        mount;          // Device mount flag (TRUE if disk was mounted successfully, FALSE otherwise)
} DISK;

typedef struct
{
    unsigned char        Name[9];
    unsigned char        Ext[4];
    unsigned char       Attr;
    unsigned short      CreateDate;
    unsigned short      CreateTime;
    unsigned short      LastAccessDate;
    unsigned short      UpdateDate;
    unsigned short      UpdateTime;
    unsigned short       FirstCluster;
    unsigned long       Size;
    unsigned short       DirClusSec; // Sector in Cluster of the directory (Position calculated)
    unsigned short      DirEntry;   // Entry in directory (step 32)
    unsigned char        Updated;
} FAT16_DIR;

// Estrutura para Nome do Arquivo
typedef struct
{
    unsigned char        Name[8];
    unsigned char        Ext[3];
} FILE_NAME;

FAT16_DIR *vdir    = 0x00609CD0;
DISK  *vdisk       = 0x00609D00;
unsigned short *vclusterdir = 0x00609DE0;
unsigned short *vclusteros  = 0x00609DE8;
unsigned char  *gDataBuffer = 0x00609DF0; // The global data sector buffer to 0x00609FF7
unsigned char  *mcfgfile   = 0x00609FF8; // onde eh carregado o arquivo de configuracao e outros arquivos 12K
unsigned short  *verroSo      = 0x0060D02E;
unsigned char  *vdiratu    = 0x0060D032; // Buffer de pasta atual 128 bytes
unsigned short  *vdiratuidx   = 0x0060D0B0; // Pointer Buffer de pasta atual 128 bytes (SO FUNCIONA NA RAM)

#define FAT16       3

#define TRUE        1
#define FALSE       0

#if !defined(NULL)
    #define NULL        '\0'
#endif

#define MEDIA_SECTOR_SIZE   512

// Demarca o Final do OS, constantes desse tipo nesse compilador vao pro final do codigo.
// Sempre verificar se esta no final mesmo

#define ATTR_READ_ONLY      0x01
#define ATTR_HIDDEN         0x02
#define ATTR_SYSTEM         0x04
#define ATTR_VOLUME         0x08
#define ATTR_LONG_NAME      0x0f
#define ATTR_DIRECTORY      0x10
#define ATTR_ARCHIVE        0x20
#define ATTR_MASK           0x3f

#define CLUSTER_EMPTY           0x0000
#define LAST_CLUSTER_FAT16      0xFFFF
#define END_CLUSTER_FAT16       0xFFF7
#define CLUSTER_FAIL_FAT16      0xFFFF

#define NUMBER_OF_unsigned charS_IN_DIR_ENTRY    32
#define DIR_DEL             0xE5
#define DIR_EMPTY           0
#define DIR_NAMESIZE        8
#define DIR_EXTENSION       3
#define DIR_NAMECOMP        (DIR_NAMESIZE+DIR_EXTENSION)

#define EOF             ((int)-1)

#define OPER_READ      0x01
#define OPER_WRITE     0x02
#define OPER_READWRITE 0x03

#define CONV_DATA    0x01
#define CONV_HORA    0x02

#define INFO_SIZE    0x01
#define INFO_CREATE  0x02
#define INFO_UPDATE  0x03
#define INFO_LAST    0x04

// Tipos para Cricao/Procura de Arquivos
#define TYPE_DIRECTORY   0x01
#define TYPE_FILE        0x02
#define TYPE_EMPTY_ENTRY 0x03
#define TYPE_CREATE_FILE 0x04
#define TYPE_CREATE_DIR  0x05
#define TYPE_DEL_FILE    0x06
#define TYPE_DEL_DIR     0x07
#define TYPE_FIRST_ENTRY 0x08
#define TYPE_NEXT_ENTRY  0x09
#define TYPE_ALL         0xFF

// Tipos para Procura de Clusters
#define FREE_FREE 0x01
#define FREE_USE  0x02
#define NEXT_FREE 0x03
#define NEXT_FULL 0x04
#define NEXT_FIND 0x05

// Codigo de Erros
#define ERRO_D_START          0xFFF0
#define ERRO_D_FILE_NOT_FOUND 0xFFF0
#define ERRO_D_READ_DISK      0xFFF1
#define ERRO_D_WRITE_DISK     0xFFF2
#define ERRO_D_OPEN_DISK      0xFFF3
#define ERRO_D_DISK_FULL      0xFFF4
#define ERRO_D_INVALID_NAME   0xFFF5
#define ERRO_D_NOT_FOUND      0xFFFF

#define ERRO_B_START          0xE0
#define ERRO_B_FILE_NOT_FOUND 0xE0
#define ERRO_B_READ_DISK      0xE1
#define ERRO_B_WRITE_DISK     0xE2
#define ERRO_B_OPEN_DISK      0xE3
#define ERRO_B_DIR_NOT_FOUND  0xE5
#define ERRO_B_CREATE_FILE    0xE6
#define ERRO_B_APAGAR_ARQUIVO 0xE7
#define ERRO_B_FILE_FOUND     0xE8
#define ERRO_B_UPDATE_DIR     0xE9
#define ERRO_B_OFFSET_READ    0xEA
#define ERRO_B_DISK_FULL      0xEB
#define ERRO_B_READ_FILE      0xEC
#define ERRO_B_WRITE_FILE     0xED
#define ERRO_B_DIR_FOUND      0xEE
#define ERRO_B_CREATE_DIR     0xEF
#define ERRO_B_NOT_FOUND      0xFF

#define RETURN_OK             0x00

//--- FAT16 Functions
void fsInit(void);
void fsVer(void);
char fsOsCommand(unsigned char *linhacomando, unsigned int ix, unsigned int iy, unsigned char *linhaarg, unsigned char *vparam, unsigned char *vparam2, unsigned char *vparam3, unsigned char* vresp);
unsigned char fsMountDisk(void);
unsigned char fsFormat (long int serialNumber, char * volumeID);
void fsSetClusterDir (unsigned short vclusdiratu);
unsigned short fsGetClusterDir (void);
unsigned char fsSectorWrite(unsigned short vcluster, unsigned char* vbuffer, unsigned char vtipo);
unsigned char fsSectorRead(unsigned short vcluster, unsigned char* vbuffer);
int fsRecSerial(unsigned char* pByte);
int fsSendSerial(unsigned char pByte);
int fsSendLongSerial(unsigned char *msg);
void fsConvClusterToTHS(unsigned short cluster, unsigned char* vtrack, unsigned char* vhead, unsigned char* vsector);
void fsReadDir(unsigned short ix, unsigned short vdata);

// Funcoes de Manipulacao de Arquivos
unsigned char fsCreateFile(char * vfilename);
unsigned char fsOpenFile(char * vfilename);
unsigned char fsCloseFile(char * vfilename, unsigned char vupdated);
unsigned long fsInfoFile(char * vfilename, unsigned char vtype);
unsigned char fsRWFile(unsigned short vclusterini, unsigned long voffset, unsigned char *buffer, unsigned char vtype);
unsigned short fsReadFile(char * vfilename, unsigned long voffset, unsigned char *buffer, unsigned short vsizebuffer);
unsigned char fsWriteFile(char * vfilename, unsigned long voffset, unsigned char *buffer, unsigned char vsizebuffer);
unsigned char fsDelFile(char * vfilename);
unsigned char fsRenameFile(char * vfilename, char * vnewname);

unsigned long loadFile(unsigned char *parquivo, unsigned short* xaddress);
void catFile(unsigned char *parquivo);

// Funcoes de Manipulacao de Diretorios
unsigned char fsMakeDir(char * vdirname);
unsigned char fsChangeDir(char * vdirname);
unsigned char fsRemoveDir(char * vdirname);
unsigned char fsPwdDir(unsigned char *vdirpath);

// Funcoes de Apoio
unsigned long fsFindInDir(char * vname, unsigned char vtype);
unsigned char fsUpdateDir(void);
unsigned short fsFindNextCluster(unsigned short vclusteratual, unsigned char vtype);
unsigned short fsFindClusterFree(unsigned char vtype);
unsigned int bcd2dec(unsigned int bcd);
int getDateTimeAtu(ds1307);
unsigned short datetimetodir(unsigned char hr_day, unsigned char min_month, unsigned char sec_year, unsigned char vtype);

/************************************************;
; Convert LBA to CHS
; AX: LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;
;************************************************/
