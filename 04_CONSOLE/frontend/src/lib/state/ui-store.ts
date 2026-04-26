import { create } from "zustand";

type UIState = {
  focusMode: boolean;
  setFocusMode: (v: boolean) => void;
};

export const useUIStore = create<UIState>((set) => ({
  focusMode: false,
  setFocusMode: (v) => set({ focusMode: v }),
}));
