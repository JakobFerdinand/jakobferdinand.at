/** @typedef {{load: (Promise<unknown>); flags: (unknown)}} ElmPagesInit */

/** @type ElmPagesInit */
export default {
  load: async function (elmLoaded) {
    const app = await elmLoaded;
  },
  flags: function () {
    return {
      height: window.innerHeight,
      width: window.innerWidth
    }
  },
};
