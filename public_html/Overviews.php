<?php
  //open a connection to dbase server 
  include 'open.php';

  //construct an array in which we'll store our data
  $dataPoints = array();


  //SQL Prepared Statements
  $sql = "CALL TopMalaria;";
  $sql2 = "CALL LowestMalaria;";
  $sql3 = "CALL TopPopulation;";
  $sql4 = "CALL LowestPopulation;";
  $sql5 = "CALL TopDemocracy;";
  $sql6 = "CALL LowestDemocracy;";
  $sql7 = "CALL TopLifeExpectancy;";
  $sql8 = "CALL LowestLifeExpectancy;";

  //execute the query, then run through the result table row by row to
  //put each row's data into our array
  if ($result = mysqli_query($conn,$sql)){
     foreach($result as $row){
        array_push($dataPoints, array( "label"=> $row["country"], "y"=> $row["population"]));
     }
  }
  
  //close the connection opened by open.php since we no longer need access to dbase
  $conn->close();
?>
<html>
<head>
<script>
window.onload = function () { 
  var chart = new CanvasJS.Chart("chartContainer", {
    animationEnabled: true,
    exportEnabled: true,
    theme: "light1", // "light1", "light2", "dark1", "dark2"
    title:{
      text: "Population"
    },
    data: [{
      type: "line", //change type to column, bar, line, area, pie, etc  
      dataPoints: <?php echo json_encode($dataPoints, JSON_NUMERIC_CHECK); ?>
    }]
  });
  chart.render(); 
}
</script>
</head>
<body>
  <div id="chartContainer" style="width: 100%;"></div>
  <script src="https://canvasjs.com/assets/script/canvasjs.min.js"></script>
</body>
</html>










<html>
<head>
<title>Overviews</title>
<link rel="stylesheet" href="style.css">
</head>
  





  <body>

    <h1>Overviews</h1>
    <h3>Team Members: KEVIN GORMAN (KGORMAN4), UTKARSH SINGH (USINGH5)</h3>

    <hr>
  <!-- List of Overviews -->
    <h3>1. The Top Malaria Countries</h3>
    <form action="oTopMalaria.php" method="post">
      <input type="submit" value="Top Malaria Countries">
    </form>

    <h3>2. The Lowest Malaria Countries</h3>
    <form action="oLowMalaria.php" method="post">
      <input type="submit" value="Lowest Malaria Countries">
    </form>

    <h3>3. The Top Population Countries</h3>
    <form action="oTopPopulation.php" method="post">
      <input type="submit" value="Top Population Countries">
    </form>

    <h3>4. The Lowest Population Countries</h3>
    <form action="oLowPopulation.php" method="post">
      <input type="submit" value="Lowest Population Countries">
    </form>

    <h3>5. The Top Democracy Index Countries</h3>
    <form action="oTopDemocracy.php" method="post">
      <input type="submit" value="Top Democracy Countries">
    </form>

    <h3>6. The Lowest Democracy Index Countries</h3>
    <form action="oLowDemocracy.php" method="post">
      <input type="submit" value="Lowest Democracy Countries">
    </form>

    <h3>7. The Top Life-Expectancy Countries</h3>
    <form action="oTopLifeExpectancy.php" method="post">
      <input type="submit" value="Top Life-Expectancy Countries">
    </form>

    <h3>8. The Lowest Life-Expectancy Countries</h3>
    <form action="oLowLifeExpectancy.php" method="post">
      <input type="submit" value="Lowest Life-Expectancy Countries">
    </form>


  </body>
</html>
