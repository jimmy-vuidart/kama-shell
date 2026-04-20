export enum SectionId {
  Dashboard = "dashboard",
  Gaming = "gaming",
  Dev = "dev"
}

export const sections = [
  { id: SectionId.Dashboard, label: "Dashboard", icon: "HOME" },
  { id: SectionId.Gaming, label: "Gaming Universe", icon: "GAME" },
  { id: SectionId.Dev, label: "Dev Universe", icon: "DEV" },
]
