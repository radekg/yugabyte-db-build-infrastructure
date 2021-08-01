#include "postgres.h"

#include "miscadmin.h"
#include "nodes/parsenodes.h"
#include "tcop/utility.h"

#define PG13_GTE (PG_VERSION_NUM >= 130000)

// Hook function:
static ProcessUtility_hook_type prev_hook	= NULL;

// Required macro for extension libraries to work:
PG_MODULE_MAGIC;

void _PG_init(void);
void _PG_fini(void);

// Error definitions:
#define EREPORT_DISALLOWED(name)                  \
    ereport(ERROR,                                          \
            (errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),       \
             errmsg("operation not allowed: \"%s\"", name)));

/*
 * IO: Hook logic.
 */
static void
example_hook(PlannedStmt *pstmt,
             const char *queryString,
             ProcessUtilityContext context,
             ParamListInfo params,
             QueryEnvironment *queryEnv,
             DestReceiver *dest,
#if PG13_GTE
             QueryCompletion *completionTag
#else
             char *completionTag
#endif
)
{
    // Get the utility statement from the planned statement
    Node   *utility_stmt = pstmt->utilityStmt;
    
    //if (!superuser())
    //{
        switch (utility_stmt->type)
		{
            case T_CreateStmt:
                {
                    CreateStmt *stmt = (CreateStmt *)utility_stmt;
                    if (stmt->tablespacename != NULL) {
                        if (strcmp(stmt->tablespacename, "pg_default") == 0) {
                            EREPORT_DISALLOWED("CREATE TABLE ... TABLESPACE pg_default");
                        }
                    }
                }

            case T_VariableSetStmt:
                {
                    VariableSetStmt *stmt = (VariableSetStmt *)utility_stmt;
                    if (strcmp(stmt->name, "default_tablespace") == 0) {
                        EREPORT_DISALLOWED("SET ... default_tablespace");
                        break;
                    }
                    if (strcmp(stmt->name, "temp_tablespaces") == 0) {
                        EREPORT_DISALLOWED("SET ... temp_tablespaces");
                        break;
                    }
                }

			// Other operations would have to be restricted
			// for the complete workload isolation.

            default:
                // ereport(LOG, (errmsg("statement type: %d", utility_stmt->type)));
                break;
        }
    //}

    // Chain to previously defined hooks
    if (prev_hook)
        prev_hook(pstmt, queryString,
                         context, params, queryEnv,
                         dest, completionTag);
    else
        standard_ProcessUtility(pstmt, queryString,
                                       context, params, queryEnv,
                                       dest, completionTag);
}

/*
 * IO: module load callback
 */
void
_PG_init(void)
{
    // Store the previous hook
    prev_hook = ProcessUtility_hook;

    // Set our hook
    ProcessUtility_hook = example_hook;

    ereport(LOG, (errmsg("example extension initialized")));
}

/*
 * IO: module unload callback
 * This is just for completion. Right now postgres doesn't call _PG_fini, see:
 * https://github.com/postgres/postgres/blob/master/src/backend/utils/fmgr/dfmgr.c#L388-L402
 */
void
_PG_fini(void)
{
    ProcessUtility_hook = prev_hook;
}
