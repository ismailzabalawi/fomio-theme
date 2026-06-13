import { apiInitializer } from "discourse/lib/api";
// Replacement-screen preferences are retired.
// Keep this initializer as a stable entry point, but do not attach late
// controller patches or route-replacement behavior here.

export default apiInitializer("1.8.0", () => {});
