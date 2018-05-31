export interface OpContextMenuLocalsMap {
  items:OpContextMenuItem[];
  contextMenuId?:string;
  [key:string]:any;
};

export interface OpContextMenuItem {
  disabled?:boolean;
  hidden?:boolean;
  icon?:string;
  href?:string;
  class?:string;
  ariaLabel?:string;
  linkText?:string;
  divider?:boolean;
  onClick?:($event:JQueryEventObject) => boolean;
}
