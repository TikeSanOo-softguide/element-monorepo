export const isMobileLayout = (): boolean => {
    return window?.matchMedia("(max-width: 767px)").matches;
};