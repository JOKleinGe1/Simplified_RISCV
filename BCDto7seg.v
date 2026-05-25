module BCDto7seg(input[3:0] din, output[6:0] abcdef);
  
  reg[127:0]rom = 128'h3F06_5B4F_666D_7D07_7F6F_777C_395E_7971;
  // see https://fr.wikipedia.org/wiki/Afficheur_7_segments
  
assign abcdef = ~ rom >>(15-din)*8;
endmodule
