local addonName, ns = ...

ns.L = {
  TANK = "Tank",
  HEALER = "Healer",
  DAMAGER = "DPS",
  SHOWING = "Showing %d of %d listings (%s)",
  PARTY_OF = "party of %d: %s",
  NO_ROLES = "no roles",
  TIP_SOLO = "Click to show only groups with an open spot for this role. Several ticked roles: any of them.",
  TIP_PARTY = "In a party: left-click adds one, right-click removes one. Groups need every counted spot open and room for your whole party.",
  FILTER_LABEL = "Open spot for:",
  SETTINGS_TITLE = "OpenSpot",
  TEMPLATE_HEADER = "5-player dungeon template",
  TEMPLATE_HELP = "How many of each role a dungeon group wants. Open spots are this minus the members who already have that role; members without a role count as DPS.",
  DEBUG_DONE = "Report saved. Type /reload to write it to disk.",
  DEBUG_NO_RESULTS = "No search results. Open the Looking For Group window and search first.",
  HELP = "/openspot: settings, /openspot debug: write a report",
}
