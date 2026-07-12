// ========== HIA REAL PROJECT REGISTRY ==========
// ID_UNICO..........: PRJPB_010K_R3_IMPLEMENT_REAL_PROJECT_REGISTRY
// GENERATED_AT......: 2026-07-11 21:44:12 -04:00
// GENERATED_UTC.....: 2026-07-12T01:44:12.5610307Z
// SOURCE............: filesystem:04_PROJECTS
// MODE..............: READ_ONLY
// NO_FAKE_DATA......: YES
// ===============================================

window.HIA_PROJECTS_REAL = Object.freeze({
    "schema":  "HIA_PROJECTS_REAL.v0.1",
    "generated_local":  "2026-07-11 21:44:12 -04:00",
    "generated_utc":  "2026-07-12T01:44:12.5610307Z",
    "source":  "filesystem:04_PROJECTS",
    "mode":  "READ_ONLY",
    "no_fake_data":  true,
    "project_count":  1,
    "projects":  [
                     {
                         "project_id":  "PRJ_0001_HIA.PRODUCT",
                         "path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT",
                         "source":  "STATE/CURRENT_STATE.json",
                         "has_current_state":  true,
                         "has_baton":  true,
                         "has_backlog":  true,
                         "has_delivery":  true,
                         "evidence":  "FRESH",
                         "session":  "active",
                         "next_action":  "PRJPB_010K | implementar registry real de proyectos desde 04_PROJECTS sin mocks | ready"
                     }
                 ],
    "validation":  {
                       "only_real_directories":  true,
                       "minimum_shape_required":  "STATE or BATON or AGILE or DELIVERY",
                       "fake_projects_allowed":  false
                   }
});