window.BENCHMARK_DATA = {
  "lastUpdate": 1654671337583,
  "repoUrl": "https://github.com/manuvanegas/SpatialRust",
  "entries": {
    "Julia benchmark result": [
      {
        "commit": {
          "author": {
            "name": "Manuela Vanegas Ferro",
            "username": "manuvanegas",
            "email": "mvanega1@asu.edu"
          },
          "committer": {
            "name": "Manuela Vanegas Ferro",
            "username": "manuvanegas",
            "email": "mvanega1@asu.edu"
          },
          "id": "24ab633eaf29a8bf31f4c0149633598e88e6c3d2",
          "message": "Update benchmark.yml\n\nUse auto-push feature",
          "timestamp": "2022-06-08T06:50:24Z",
          "url": "https://github.com/manuvanegas/SpatialRust/commit/24ab633eaf29a8bf31f4c0149633598e88e6c3d2"
        },
        "date": 1654671336228,
        "tool": "julia",
        "benches": [
          {
            "name": "ABM/steps: 1600, nlesions: 1",
            "value": 22026054602,
            "unit": "ns",
            "extra": "gctime=855032091\nmemory=2680319859\nallocs=105843799\nparams={\"gctrial\":true,\"time_tolerance\":0.05,\"samples\":10000,\"evals\":1,\"gcsample\":false,\"seconds\":5,\"overhead\":0,\"memory_tolerance\":0.01}"
          },
          {
            "name": "ABM/steps: 1600, nlesions: 5",
            "value": 15566413628,
            "unit": "ns",
            "extra": "gctime=828632305\nmemory=5302769336\nallocs=170222758\nparams={\"gctrial\":true,\"time_tolerance\":0.05,\"samples\":10000,\"evals\":1,\"gcsample\":false,\"seconds\":5,\"overhead\":0,\"memory_tolerance\":0.01}"
          },
          {
            "name": "ABM/steps: 1600, nlesions: 25",
            "value": 20118914876,
            "unit": "ns",
            "extra": "gctime=1092204354\nmemory=9231284184\nallocs=190911354\nparams={\"gctrial\":true,\"time_tolerance\":0.05,\"samples\":10000,\"evals\":1,\"gcsample\":false,\"seconds\":5,\"overhead\":0,\"memory_tolerance\":0.01}"
          }
        ]
      }
    ]
  }
}