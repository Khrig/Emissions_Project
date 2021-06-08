##Repository for fourth year project "Reducing Campus Emissions Using Machine Learning"##

#Chris

***

**Requirements:**
in addition to Chris/requirements.txt, tesseract will need to be installed.


**Instructions:**

1. Put pdf versions of plans in Chris/building plans

2. run fitz pdf to image

3. run building info extractor

4. check metadata is ok in /results

5. run text area detect

6. optionally check and correct outputs, copy to building plans corrected.csv. Can see what tesseract has detected by setting single building to true in text area detect, alternatively building plans corrected already has a complete set of results

7. correct plans such that the external contour of the buildings does not intersect with the boxes of the plan and that doughnut shaped buildings have holes in the exterior, as detailed in report.

8. place corrected plans and all other plans to run further steps on in to building plans corrected, alternatively, corrected versions are available on teams.

9. run contour analysis, can check wether the correct contour has been found by adding the buildings name to disp_paths

10. run thermal analysis

11. run model to simulate a building. only working with George Fox at the moment as data is not great for other buildings


Final versions of the results I generated can be found in Chris/results


#Katie

#Henry

*...*
