(* Copyright 2023 Yawar Amin

   This file is part of dream-html.

   dream-html is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation, either version 3 of the License, or (at your option) any
   later version.

   dream-html is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along with
   dream-html. If not, see <https://www.gnu.org/licenses/>. *)

open Pure_html

let%expect_test "MathML" =
  let mathml_node =
    let open HTML in
    let open MathML in
    p []
      [ math
          [style_ ""]
          [ mtable []
              [ mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mrow []
                                  [ mrow []
                                      [ mi [] [txt "a"];
                                        mo [] [txt "⁢"];
                                        msup []
                                          [mi [] [txt "x"]; mn [] [txt "2"]] ];
                                    mo [] [txt "+"];
                                    mi [] [txt "b"];
                                    mo [] [txt "⁢"];
                                    mi [] [txt "x"] ];
                                mo [] [txt "+"];
                                mi [] [txt "c"] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd [] [mn [] [txt "0"]] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mi [] [txt "a"];
                                mo [] [txt "⁢"];
                                msup [] [mi [] [txt "x"]; mn [] [txt "2"]] ];
                            mo [] [txt "+"];
                            mi [] [txt "b"];
                            mo [] [txt "⁢"];
                            mi [] [txt "x"] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd [] [mo [] [txt "−"]; mi [] [txt "c"]] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow [] [msup [] [mi [] [txt "x"]; mn [] [txt "2"]]];
                            mo [] [txt "+"];
                            mfrac [] [mi [] [txt "b"]; mi [] [txt "a"]];
                            mo [] [txt "⁤"];
                            mi [] [txt "x"] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow [] [mo [] [txt "−"]; mi [] [txt "c"]];
                            mi [] [txt "a"] ] ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "Divide out leading coefficient."] ] ] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mrow []
                                  [msup [] [mi [] [txt "x"]; mn [] [txt "2"]]];
                                mo [] [txt "+"];
                                mfrac []
                                  [mrow [] [mi [] [txt "b"]]; mi [] [txt "a"]];
                                mo [] [txt "⁤"];
                                mi [] [txt "x"];
                                mo [] [txt "+"];
                                msup []
                                  [ mrow []
                                      [ mo [] [txt "("];
                                        mfrac []
                                          [ mrow [] [mi [] [txt "b"]];
                                            mrow []
                                              [mn [] [txt "2"]; mi [] [txt "a"]]
                                          ];
                                        mo [] [txt ")"] ];
                                    mn [] [txt "2"] ] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mrow []
                          [ mfrac []
                              [ mrow []
                                  [ mo [] [txt "−"];
                                    mi [] [txt "c"];
                                    mo [] [txt "("];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mo [] [txt ")"] ];
                                mrow []
                                  [ mi [] [txt "a"];
                                    mo [] [txt "("];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mo [] [txt ")"] ] ];
                            mo [] [txt "+"];
                            mfrac []
                              [ mrow []
                                  [msup [] [mi [] [txt "b"]; mn [] [txt "2"]]];
                                mrow []
                                  [ mn [] [txt "4"];
                                    msup [] [mi [] [txt "a"]; mn [] [txt "2"]]
                                  ] ] ] ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "Complete the square."] ] ] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mo [] [txt "("];
                                mi [] [txt "x"];
                                mo [] [txt "+"];
                                mfrac []
                                  [ mrow [] [mi [] [txt "b"]];
                                    mrow [] [mn [] [txt "2"]; mi [] [txt "a"]]
                                  ];
                                mo [] [txt ")"];
                                mo [] [txt "("];
                                mi [] [txt "x"];
                                mo [] [txt "+"];
                                mfrac []
                                  [ mrow [] [mi [] [txt "b"]];
                                    mrow [] [mn [] [txt "2"]; mi [] [txt "a"]]
                                  ];
                                mo [] [txt ")"] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow []
                              [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                mo [] [txt "−"];
                                mn [] [txt "4"];
                                mi [] [txt "a"];
                                mi [] [txt "c"] ];
                            mrow []
                              [ mn [] [txt "4"];
                                msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ] ]
                      ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "Discriminant revealed."] ] ] ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ msup []
                                  [ mrow []
                                      [ mo [] [txt "("];
                                        mi [] [txt "x"];
                                        mo [] [txt "+"];
                                        mfrac []
                                          [ mrow [] [mi [] [txt "b"]];
                                            mrow []
                                              [mn [] [txt "2"]; mi [] [txt "a"]]
                                          ];
                                        mo [] [txt ")"] ];
                                    mn [] [txt "2"] ] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow []
                              [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                mo [] [txt "−"];
                                mn [] [txt "4"];
                                mi [] [txt "a"];
                                mi [] [txt "c"] ];
                            mrow []
                              [ mn [] [txt "4"];
                                msup [] [mi [] [txt "a"]; mn [] [txt "2"]] ] ]
                      ];
                    mtd []
                      [ mrow []
                          [mtext [style_ "color: red; font-size: 10pt;"] []] ]
                  ];
                mtr []
                  [ mtd []
                      [ mrow []
                          [ mrow []
                              [ mrow []
                                  [ mi [] [txt "x"];
                                    mo [] [txt "+"];
                                    mfrac []
                                      [ mrow [] [mi [] [txt "b"]];
                                        mrow []
                                          [mn [] [txt "2"]; mi [] [txt "a"]] ]
                                  ] ] ] ];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ msqrt []
                          [ mfrac []
                              [ mrow []
                                  [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                    mo [] [txt "−"];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mi [] [txt "c"] ];
                                mrow []
                                  [ mn [] [txt "4"];
                                    msup [] [mi [] [txt "a"]; mn [] [txt "2"]]
                                  ] ] ] ];
                    mtd []
                      [ mrow []
                          [mtext [style_ "color: red; font-size: 10pt;"] []] ]
                  ];
                mtr []
                  [ mtd [] [mi [] [txt "x"]];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow [] [mo [] [txt "−"]; mi [] [txt "b"]];
                            mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ];
                        mo [] [txt "±"];
                        mrow []
                          [mo [] [txt "{"]; mi [] [txt "C"]; mo [] [txt "}"]];
                        msqrt []
                          [ mfrac []
                              [ mrow []
                                  [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                    mo [] [txt "−"];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mi [] [txt "c"] ];
                                mrow []
                                  [ mn [] [txt "4"];
                                    msup [] [mi [] [txt "a"]; mn [] [txt "2"]]
                                  ] ] ] ];
                    mtd []
                      [ mrow []
                          [ mtext
                              [style_ "color: red; font-size: 10pt;"]
                              [txt "There's the vertex formula."] ] ] ];
                mtr []
                  [ mtd [] [mi [] [txt "x"]];
                    mtd [] [mo [] [txt "="]];
                    mtd []
                      [ mfrac []
                          [ mrow []
                              [ mo [] [txt "−"];
                                mi [] [txt "b"];
                                mo [] [txt "±"];
                                mrow []
                                  [ mo [] [txt "{"];
                                    mi [] [txt "C"];
                                    mo [] [txt "}"] ];
                                msqrt []
                                  [ msup [] [mi [] [txt "b"]; mn [] [txt "2"]];
                                    mo [] [txt "−"];
                                    mn [] [txt "4"];
                                    mi [] [txt "a"];
                                    mi [] [txt "c"] ] ];
                            mrow [] [mn [] [txt "2"]; mi [] [txt "a"]] ] ];
                    mtd []
                      [ mrow []
                          [mtext [style_ "color: red; font-size: 10pt;"] []] ]
                  ] ] ] ]
  in
  mathml_node |> to_xml |> print_endline;
  [%expect
    {|
    <p>
      <math style="">
        <mtable>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <mrow>
                    <mrow>
                      <mi>a</mi>
                      <mo>⁢</mo>
                      <msup>
                        <mi>x</mi>
                        <mn>2</mn>
                      </msup>
                    </mrow>
                    <mo>+</mo>
                    <mi>b</mi>
                    <mo>⁢</mo>
                    <mi>x</mi>
                  </mrow>
                  <mo>+</mo>
                  <mi>c</mi>
                </mrow>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mn>0</mn>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <mi>a</mi>
                  <mo>⁢</mo>
                  <msup>
                    <mi>x</mi>
                    <mn>2</mn>
                  </msup>
                </mrow>
                <mo>+</mo>
                <mi>b</mi>
                <mo>⁢</mo>
                <mi>x</mi>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mo>−</mo>
              <mi>c</mi>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <msup>
                    <mi>x</mi>
                    <mn>2</mn>
                  </msup>
                </mrow>
                <mo>+</mo>
                <mfrac>
                  <mi>b</mi>
                  <mi>a</mi>
                </mfrac>
                <mo>⁤</mo>
                <mi>x</mi>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mfrac>
                <mrow>
                  <mo>−</mo>
                  <mi>c</mi>
                </mrow>
                <mi>a</mi>
              </mfrac>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;">Divide out leading coefficient.</mtext>
              </mrow>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <mrow>
                    <msup>
                      <mi>x</mi>
                      <mn>2</mn>
                    </msup>
                  </mrow>
                  <mo>+</mo>
                  <mfrac>
                    <mrow>
                      <mi>b</mi>
                    </mrow>
                    <mi>a</mi>
                  </mfrac>
                  <mo>⁤</mo>
                  <mi>x</mi>
                  <mo>+</mo>
                  <msup>
                    <mrow>
                      <mo>(</mo>
                      <mfrac>
                        <mrow>
                          <mi>b</mi>
                        </mrow>
                        <mrow>
                          <mn>2</mn>
                          <mi>a</mi>
                        </mrow>
                      </mfrac>
                      <mo>)</mo>
                    </mrow>
                    <mn>2</mn>
                  </msup>
                </mrow>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mrow>
                <mfrac>
                  <mrow>
                    <mo>−</mo>
                    <mi>c</mi>
                    <mo>(</mo>
                    <mn>4</mn>
                    <mi>a</mi>
                    <mo>)</mo>
                  </mrow>
                  <mrow>
                    <mi>a</mi>
                    <mo>(</mo>
                    <mn>4</mn>
                    <mi>a</mi>
                    <mo>)</mo>
                  </mrow>
                </mfrac>
                <mo>+</mo>
                <mfrac>
                  <mrow>
                    <msup>
                      <mi>b</mi>
                      <mn>2</mn>
                    </msup>
                  </mrow>
                  <mrow>
                    <mn>4</mn>
                    <msup>
                      <mi>a</mi>
                      <mn>2</mn>
                    </msup>
                  </mrow>
                </mfrac>
              </mrow>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;">Complete the square.</mtext>
              </mrow>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <mo>(</mo>
                  <mi>x</mi>
                  <mo>+</mo>
                  <mfrac>
                    <mrow>
                      <mi>b</mi>
                    </mrow>
                    <mrow>
                      <mn>2</mn>
                      <mi>a</mi>
                    </mrow>
                  </mfrac>
                  <mo>)</mo>
                  <mo>(</mo>
                  <mi>x</mi>
                  <mo>+</mo>
                  <mfrac>
                    <mrow>
                      <mi>b</mi>
                    </mrow>
                    <mrow>
                      <mn>2</mn>
                      <mi>a</mi>
                    </mrow>
                  </mfrac>
                  <mo>)</mo>
                </mrow>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mfrac>
                <mrow>
                  <msup>
                    <mi>b</mi>
                    <mn>2</mn>
                  </msup>
                  <mo>−</mo>
                  <mn>4</mn>
                  <mi>a</mi>
                  <mi>c</mi>
                </mrow>
                <mrow>
                  <mn>4</mn>
                  <msup>
                    <mi>a</mi>
                    <mn>2</mn>
                  </msup>
                </mrow>
              </mfrac>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;">Discriminant revealed.</mtext>
              </mrow>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <msup>
                    <mrow>
                      <mo>(</mo>
                      <mi>x</mi>
                      <mo>+</mo>
                      <mfrac>
                        <mrow>
                          <mi>b</mi>
                        </mrow>
                        <mrow>
                          <mn>2</mn>
                          <mi>a</mi>
                        </mrow>
                      </mfrac>
                      <mo>)</mo>
                    </mrow>
                    <mn>2</mn>
                  </msup>
                </mrow>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mfrac>
                <mrow>
                  <msup>
                    <mi>b</mi>
                    <mn>2</mn>
                  </msup>
                  <mo>−</mo>
                  <mn>4</mn>
                  <mi>a</mi>
                  <mi>c</mi>
                </mrow>
                <mrow>
                  <mn>4</mn>
                  <msup>
                    <mi>a</mi>
                    <mn>2</mn>
                  </msup>
                </mrow>
              </mfrac>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;" />
              </mrow>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mrow>
                <mrow>
                  <mrow>
                    <mi>x</mi>
                    <mo>+</mo>
                    <mfrac>
                      <mrow>
                        <mi>b</mi>
                      </mrow>
                      <mrow>
                        <mn>2</mn>
                        <mi>a</mi>
                      </mrow>
                    </mfrac>
                  </mrow>
                </mrow>
              </mrow>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <msqrt>
                <mfrac>
                  <mrow>
                    <msup>
                      <mi>b</mi>
                      <mn>2</mn>
                    </msup>
                    <mo>−</mo>
                    <mn>4</mn>
                    <mi>a</mi>
                    <mi>c</mi>
                  </mrow>
                  <mrow>
                    <mn>4</mn>
                    <msup>
                      <mi>a</mi>
                      <mn>2</mn>
                    </msup>
                  </mrow>
                </mfrac>
              </msqrt>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;" />
              </mrow>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mi>x</mi>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mfrac>
                <mrow>
                  <mo>−</mo>
                  <mi>b</mi>
                </mrow>
                <mrow>
                  <mn>2</mn>
                  <mi>a</mi>
                </mrow>
              </mfrac>
              <mo>±</mo>
              <mrow>
                <mo>{</mo>
                <mi>C</mi>
                <mo>}</mo>
              </mrow>
              <msqrt>
                <mfrac>
                  <mrow>
                    <msup>
                      <mi>b</mi>
                      <mn>2</mn>
                    </msup>
                    <mo>−</mo>
                    <mn>4</mn>
                    <mi>a</mi>
                    <mi>c</mi>
                  </mrow>
                  <mrow>
                    <mn>4</mn>
                    <msup>
                      <mi>a</mi>
                      <mn>2</mn>
                    </msup>
                  </mrow>
                </mfrac>
              </msqrt>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;">There's the vertex formula.</mtext>
              </mrow>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mi>x</mi>
            </mtd>
            <mtd>
              <mo>=</mo>
            </mtd>
            <mtd>
              <mfrac>
                <mrow>
                  <mo>−</mo>
                  <mi>b</mi>
                  <mo>±</mo>
                  <mrow>
                    <mo>{</mo>
                    <mi>C</mi>
                    <mo>}</mo>
                  </mrow>
                  <msqrt>
                    <msup>
                      <mi>b</mi>
                      <mn>2</mn>
                    </msup>
                    <mo>−</mo>
                    <mn>4</mn>
                    <mi>a</mi>
                    <mi>c</mi>
                  </msqrt>
                </mrow>
                <mrow>
                  <mn>2</mn>
                  <mi>a</mi>
                </mrow>
              </mfrac>
            </mtd>
            <mtd>
              <mrow>
                <mtext style="color: red; font-size: 10pt;" />
              </mrow>
            </mtd>
          </mtr>
        </mtable>
      </math>
    </p>
    |}]