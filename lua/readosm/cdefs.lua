local ffi = require"ffi"

-- C declarations taken more or less verbatim from readosm.h

ffi.cdef
[[
typedef struct readosm_tag_struct
{
  const char *_key;
  const char *_value;
} readosm_tag;

typedef struct readosm_node_struct
{
  const long long id;
  const double latitude;
  const double longitude;
  const int version;
  const long long changeset;
  const char *_user;
  const int uid;
  const char *_timestamp;
  const int tag_count;
  const readosm_tag *_tags;
} readosm_node;

typedef struct readosm_way_struct
{
  const long long id;
  const int version;
  const long long changeset;
  const char *_user;
  const int uid;
  const char *_timestamp;
  const int node_ref_count;
  const long long *_node_refs;
  const int tag_count;
  const readosm_tag *_tags;
} readosm_way;

typedef struct readosm_member_struct
{
  const int _member_type;
  const long long id;
  const char *_role;
} readosm_member;

typedef struct readosm_relation_struct
{
  const long long id;
  const int version;
  const long long changeset;
  const char *_user;
  const int uid;
  const char *_timestamp;
  const int member_count;
  const readosm_member *_members;
  const int tag_count;
  const readosm_tag *_tags;
} readosm_relation;

typedef int (*readosm_node_callback) (const void *user_data, const readosm_node *node);
typedef int (*readosm_way_callback) (const void *user_data, const readosm_way *way);
typedef int (*readosm_relation_callback) (const void *user_data, const readosm_relation *relation);

int readosm_open (const char *path, const void **osm_handle);
int readosm_close (const void *osm_handle);
int readosm_parse (const void *osm_handle, const void *user_data,
                   readosm_node_callback node_fnct, readosm_way_callback way_fnct,
                   readosm_relation_callback relation_fnct);
]]


local C =
{
  -- type codes
  READOSM_UNDEFINED                     = -1234567890,
  READOSM_MEMBER_NODE                   =  7361,
  READOSM_MEMBER_WAY                    =  6731,
  READOSM_MEMBER_RELATION               =  3671,

  -- Error codes
  READOSM_OK                            =  0,
  READOSM_INVALID_SUFFIX                = -1,
  READOSM_FILE_NOT_FOUND                = -2,
  READOSM_NULL_HANDLE                   = -3,
  READOSM_INVALID_HANDLE                = -4,
  READOSM_INSUFFICIENT_MEMORY           = -5,
  READOSM_CREATE_XML_PARSER_ERROR       = -6,
  READOSM_READ_ERROR                    = -7,
  READOSM_XML_ERROR                     = -8,
  READOSM_INVALID_PBF_HEADER            = -9,
  READOSM_UNZIP_ERROR                   = -10,
  READOSM_ABORT                         = -11,
}


local M =
{
  -- it looks like readosm returns different values depending whether it's
  -- reading pbf (0, 1, 2) or XML (the defines)
  [0]                                   = "node",
  [1]                                   = "way",
  [2]                                   = "relation",

  [C.READOSM_UNDEFINED]                 = "undefined",
  [C.READOSM_MEMBER_NODE]               = "node",
  [C.READOSM_MEMBER_WAY]                = "way",
  [C.READOSM_MEMBER_RELATION]           = "relation",
}


local E =
{
  [C.READOSM_INVALID_SUFFIX]            = "filename suffix is not .osm or .pbf",
  [C.READOSM_FILE_NOT_FOUND]            = "file does not exist or is not readable",
  [C.READOSM_NULL_HANDLE]               = "null handle",
  [C.READOSM_INVALID_HANDLE]            = "invalid handle",
  [C.READOSM_INSUFFICIENT_MEMORY]       = "insufficient memory",
  [C.READOSM_CREATE_XML_PARSER_ERROR]   = "couldn't create XML parser",
  [C.READOSM_READ_ERROR]                = "read error",
  [C.READOSM_XML_ERROR]                 = "XML parser error",
  [C.READOSM_INVALID_PBF_HEADER]        = "invalid PBF header",
  [C.READOSM_UNZIP_ERROR]               = "unZip error",
  [C.READOSM_ABORT]                     = "user requested parser abort",
}


return { constants = C, error_map = E, member_map = M }

