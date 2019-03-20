USE [TubularDataSystems_SIW141021]
GO

/****** Object:  StoredProcedure [dbo].[sp_INVSTK_by_Filter2]    Script Date: 11/6/2014 8:32:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =======================================================================
-- Author:		 reynolds
-- Create date: 2008
-- Description: builds where clause for vw_INVSTK
-- KF 10/30/09 - include columns for v128 changes. DBupdate100011
-- KF 11/5/09  - HF v129
-- KF 11/11/09 - v131 changes DBUpdate 100017
-- KF 12/09    - v135 changes dbUpdate 100027
--    SDGTDS_WO - Add WorkOrderID
-- =======================================================================
ALTER PROCEDURE [dbo].[sp_INVSTK_by_Filter2]
    /* Input Parameters */
		@DisplayLevel INT = NULL,
      @WellChg NVARCHAR(30) = NULL,
      @AFENo NVARCHAR(30) = NULL,
      @OrderKey1 NVARCHAR(30) = NULL,
      @OrderKey2 NVARCHAR(30) = NULL,
      @ItemKey1 NVARCHAR(30) = NULL,
      @ItemKey2 NVARCHAR(30) = NULL,
      @OwnerName NVARCHAR(50) = NULL,
      @EndUserName NVARCHAR(50) = NULL,
      @SupplierName NVARCHAR(50) = NULL,
      @CustRefNo NVARCHAR(50) = NULL,
      @MaterialID NVARCHAR(50) = NULL,
      ---------------
      --@WorkOrderID NVARCHAR(50) = NULL,
      ------------------
      @RackNo NVARCHAR(50) = NULL,
      @Status NVARCHAR(20) = NULL,
      @ReleaseID NVARCHAR(10) = NULL,
      @Type NVARCHAR(50) = NULL,
      @NewUsed NVARCHAR(50) = NULL,
      @InternalCondition NVARCHAR(50) = NULL,
      @SizeWeight NVARCHAR(50) = NULL,
      @Size NVARCHAR(50) = NULL,
      @Weight NVARCHAR(50) = NULL,
      @Thread NVARCHAR(50) = NULL,
      @Grade NVARCHAR(50) = NULL,
      @Connection NVARCHAR(50) = NULL,
      @Range NVARCHAR(50) = NULL,
      
      -----------  
      @SizeWeight2 NVARCHAR(50) = NULL,
      @Size2 NVARCHAR(50) = NULL,
      @Weight2 NVARCHAR(50) = NULL,
      @Thread2 NVARCHAR(50) = NULL,
      @Connection2 NVARCHAR(50) = NULL,
  --------------

      
      @Manufacture NVARCHAR(50) = NULL,
      @Design NVARCHAR(50) = NULL,
      @Color NVARCHAR(50) = NULL,
      @Class NVARCHAR(50) = NULL,
      @Notation NVARCHAR(50) = NULL,
      @FFDesc NVARCHAR(70) = NULL,
      @FieldList NVARCHAR(800) = NULL,
      @GroupBy NVARCHAR(800) = NULL,
      @date date =null
AS 
      SET NoCount ON
    /* Variable Declaration */
      DECLARE @SQLWhere AS NVARCHAR(4000)
      DECLARE @SQLQuery AS NVARCHAR(4000)
      
      if @date is not null
      begin
      
				select invstkid, 
				case when  truckmode ='R' then  quantity else -1 * quantity end as quantity,
				case when  truckmode ='R' then  length else -1 * length end as length,       
				 isnull(dateout, datein) as date  into #s
				from trkitem a inner join trklogs b
				on a.trucklogid=b.trucklogid


				insert into #s
				select  f_invstkid as invstkid, -1*quantity as quantity, -1*length as length , date  
				from vw_invmov

				insert into #s
				select  T_invstkid as invstkid, quantity, length, date    
				from vw_invmov



				insert into #s
				select f_invstkid as invstkid, -1* quantity as quantity, -1* length as length, date
				from vw_invrelitem --#s2 

				insert into #s
				select rel_invstkid as invstkid,  quantity, length, date
				from  vw_invrelitem -- #s2 


				insert into #s
				select ninvstkid as invstkid, nquantity as quantity, declengthtoAdjust as length, dateDateAdjusted as date
				from dbo.InvAdjustment


				
				insert into #s
				select  f_invstkid as invstkid, -1*quantity as quantity, -1*length as length , date  
				from dbo.InvTransfer

				insert into #s
				select  T_invstkid as invstkid, quantity, length, date    
				from dbo.InvTransfer

				update #s
				set quantity = -1 * quantity,
				length= -1 * length
				
				insert into #s
				select invstkid, quantity, length, getdate() as date
				from invstk
											
				
						
				 SELECT  b.InvStkID, OpenAuth, OpenRcvr, OpenShip, OpenRels, CustRefNo, MaterialID, 
          WellChg, AFENo, OrderKey1, OrderKey2, ItemKey1, ItemKey2, OwnerNo, ownername,
          EndUser, endusername, Supplier, suppliername, Status, 
          
          case when type in ('x-over', 'other', 'pup joints') then 0 else b.Quantity end as Quantity, 
          
          case when type in ('x-over', 'other', 'pup joints') then 0 else b.Length end as Length, 
          
          ReleaseID,
          Type, NewUsed, InternalCondition, Size, Weight, SizeWeight, Grade, Thread, 
           Connection, Range, PupLength, Manufacture, Design, Color, Class, Notation, 
          FreeForm, SizeDec, WeightDec, ProtWeight, Address1, Address2, City, State, 
          PostalCode, Country, Contact, PhoneVoice, PhoneFax, RackNo, CustReserve1,
          
          SizeDec2,WeightDec2,ProtWeight2,Size2,Weight2,SizeWeight2,
          Thread2,Connection2
          into #t
          
          FROM vw_INVSTK a inner join
          
          (SELECT  InvStkID, sum(Quantity) as quantity, sum(length) as length 
          	FROM  #s --dbo.vw_InvMov_TrkItem_TrkLog_InvStk2
				    where  Date >= @date group by invstkid  ) b
           
           on a.invstkid =b.invstkid
      end
      --else 

        --SET @SQLWhere = '((Quantity <> 0) Or (Length <> 0)) '
        
        SET @SQLWhere = '((Quantity <> 0) Or (Length <> 0) or (OpenRcvr > 0)  or ( type  in (''x-over'',''other'', ''pup joints'') ))'
        
        
      
      
      IF @WellChg IS NOT NULL AND @WellChg <>'0'
         SET @SQLWhere = @SQLWhere + ' And (WellChg LIKE ''' + @WellChg + ''') '
      ELSE IF @WellChg = '0'
			SET @SQLWhere = @SQLWhere + ' And (WellChg = '''') '
			
      IF @AFENo IS NOT NULL AND @AFENo <> '0'
         SET @SQLWhere = @SQLWhere + ' And (AFENo LIKE ''' + @AFENo + ''') '
      ELSE IF @AFENo = '0'
			SET @SQLWhere = @SQLWhere + ' And (AFENo = '''') '
         
      IF @OrderKey1 IS NOT NULL AND @OrderKey1 <> '0'
         SET @SQLWhere = @SQLWhere + ' And (OrderKey1 LIKE ''' + @OrderKey1 + ''') '
      ELSE IF @OrderKey1 ='0'
			SET @SQLWhere = @SQLWhere + ' And (OrderKey1 = '''') '
			
      IF @OrderKey2 IS NOT NULL AND @OrderKey2 <> '0'
         SET @SQLWhere = @SQLWhere + ' And (OrderKey2 LIKE ''' + @OrderKey2 + ''') '
      ELSE IF @OrderKey2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (OrderKey2 = '''') '

      IF @ItemKey1 IS NOT NULL AND @ItemKey1 <> '0'
         SET @SQLWhere = @SQLWhere + ' And (ItemKey1 LIKE ''' + @ItemKey1 + ''') '
      ELSE IF @ItemKey1 = '0'
			SET @SQLWhere = @SQLWhere + ' And (ItemKey1 = '''') '

      IF @ItemKey2 IS NOT NULL AND @ItemKey2 <> '0'
         SET @SQLWhere = @SQLWhere + ' And (ItemKey2 LIKE ''' + @ItemKey2 + ''') '
      ELSE IF @ItemKey2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (ItemKey2 = '''') '

      IF @OwnerName IS NOT NULL AND @OwnerName <> '0'
         SET @SQLWhere = @SQLWhere + ' And (OwnerName LIKE ''' + @OwnerName + ''') '
      ELSE IF @OwnerName = '0' -- Owner CAN'T BE NULL!!!
			SET @SQLWhere = @SQLWhere + ' And (OwnerName IS NULL) '

      IF @EndUserName IS NOT NULL AND @EndUserName <> '0'
         SET @SQLWhere = @SQLWhere + ' And (EndUserName LIKE ''' + @EndUserName + ''') '
      ELSE IF @EndUserName = '0' -- End User CAN'T BE NULL!!!
			SET @SQLWhere = @SQLWhere + ' And (EndUserName IS NULL) '

      IF @SupplierName IS NOT NULL AND @SupplierName <>'0'
         SET @SQLWhere = @SQLWhere + ' And (SupplierName LIKE ''' + @SupplierName + ''') '
      ELSE IF @SupplierName = '0' -- Supplier CAN'T BE NULL!!!
			SET @SQLWhere = @SQLWhere + ' And (SupplierName IS NULL) '

      IF @CustRefNo IS NOT NULL AND @CustRefNo <> '0'
         SET @SQLWhere = @SQLWhere + ' And (CustRefNo LIKE ''' + @CustRefNo + ''') '
      ELSE IF @CustRefNo = '0'
			SET @SQLWhere = @SQLWhere + ' And (CustRefNo = '''') '

      IF @MaterialID IS NOT NULL AND @MaterialID <> '0'
         SET @SQLWhere = @SQLWhere + ' And (MaterialID LIKE ''' + @MaterialID + ''') '
      ELSE IF @MaterialID = '0' -- Material ID CAN NOT BE NULL
			SET @SQLWhere = @SQLWhere + ' And (MaterialID IS NULL) '

---------------------

	--IF @WorkOrderID IS NOT NULL AND @WorkOrderID <> '0'
	--   SET @SQLWhere = @SQLWhere + ' And (WorkOrderID LIKE ''' + @WorkOrderID + ''') '
	--ELSE IF @WorkOrderID = '0'
	--	SET @SQLWhere = @SQLWhere + ' And (WorkOrderID IS NULL) '

----------------------


      IF @RackNo IS NOT NULL AND @RackNo <> '0'
         SET @SQLWhere = @SQLWhere + ' And (RackNo LIKE ''' + @RackNo + ''') '
      ELSE IF @RackNo = '0' -- RACK NO CAN NOT BE NULL
			SET @SQLWhere = @SQLWhere + ' And (RackNo IS NULL) '

      -- Status searches will accomodate ntuples
      IF @Status IS NOT NULL AND @Status <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Status IN ' + @Status + ' )'
      ELSE IF @Status = '0' -- STATUS CAN NOT BE NULL
			SET @SQLWhere = @SQLWhere + ' And (Status IS NULL) '

      IF @ReleaseID IS NOT NULL AND @ReleaseID <> '0'
         SET @SQLWhere = @SQLWhere + ' And (ReleaseID LIKE ''' + @ReleaseID + ''') '
      ELSE IF @ReleaseID IS NOT NULL AND @ReleaseID = '0'
         SET @SQLWhere = @SQLWhere + ' And ((ReleaseID IS NULL) OR (ReleaseID=0))'
      
      IF @Type IS NOT NULL AND @Type <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Type LIKE ''' + @Type + ''')'
      ELSE IF @Type = '0' -- TYPE CAN NOT BE NULL
			SET @SQLWhere = @SQLWhere + ' And (Type IS NULL) '

      IF @NewUsed IS NOT NULL AND @NewUsed <> '0'
         SET @SQLWhere = @SQLWhere + ' And (NewUsed LIKE ''' + @NewUsed + ''')'
      ELSE IF @NewUsed = '0'
			SET @SQLWhere = @SQLWhere + ' And (NewUsed IS NULL) '

      IF @InternalCondition IS NOT NULL AND @InternalCondition <> '0'
         SET @SQLWhere = @SQLWhere + ' And (InternalCondition LIKE ''' + @InternalCondition + ''')'
      ELSE IF @InternalCondition = '0'
			SET @SQLWhere = @SQLWhere + ' And (InternalCondition IS NULL) '

      IF @Thread IS NOT NULL AND @Thread <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Thread LIKE ''' + @Thread + ''')'
      ELSE IF @Thread = '0'
			SET @SQLWhere = @SQLWhere + ' And (Thread IS NULL) '

      IF @Grade IS NOT NULL AND @Grade <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Grade LIKE ''' + @Grade + ''')'
      ELSE IF @Grade = '0'
			SET @SQLWhere = @SQLWhere + ' And (Grade IS NULL) '

      IF @Connection IS NOT NULL AND @Connection <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Connection LIKE ''' + @Connection + ''')'
      ELSE IF @Connection = '0'
			SET @SQLWhere = @SQLWhere + ' And (Connection IS NULL) '

      IF @Range IS NOT NULL AND @Range <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Range LIKE ''' + @Range + ''')'
      ELSE IF @Range = '0'
			SET @SQLWhere = @SQLWhere + ' And (Range IS NULL) '

      IF @Manufacture IS NOT NULL AND @Manufacture <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Manufacture LIKE ''' + @Manufacture + ''')'
      ELSE IF @Manufacture = '0'
			SET @SQLWhere = @SQLWhere + ' And (Manufacture IS NULL) '

      IF @Design IS NOT NULL AND @Design <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Design LIKE ''' + @Design + ''')'
      ELSE IF @Design = '0'
			SET @SQLWhere = @SQLWhere + ' And (Design IS NULL) '

      IF @Color IS NOT NULL AND @Color <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Color LIKE ''' + @Color + ''')'
      ELSE IF @Color = '0'
			SET @SQLWhere = @SQLWhere + ' And (Color IS NULL) '

      IF @Class IS NOT NULL AND @Class <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Class LIKE ''' + @Class + ''')'
      ELSE IF @Class = '0'
         SET @SQLWhere = @SQLWhere + ' And (Class IS NULL) '

      IF @Notation IS NOT NULL AND @Notation <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Notation LIKE ''' + @Notation + ''')'
      ELSE IF @Notation = '0'
			SET @SQLWhere = @SQLWhere + ' And (Notation IS NULL) '

      IF @FFDesc IS NOT NULL AND @FFDesc <> '0'
         SET @SQLWhere = @SQLWhere + ' And (FreeForm LIKE ''' + @FFDesc + ''')'
      ELSE IF @FFDesc = '0'
			SET @SQLWhere = @SQLWhere + ' And (FreeForm = '''') '

      IF @SizeWeight IS NOT NULL AND @SizeWeight <> '0'
			SET @SQLWhere = @SQLWhere + ' And (SizeWeight LIKE ''' + @SizeWeight + ''')'
		ELSE IF @SizeWeight = '0'
			SET @SQLWhere = @SQLWhere + ' And (SizeWeight IS NULL) '
      
      IF @Size IS NOT NULL AND @Size <> '0'
			SET @SQLWhere = @SQLWhere + ' And (Size LIKE ''' + @Size + ''')'
		ELSE IF @Size = '0'
			SET @SQLWhere = @SQLWhere + ' And (Size IS NULL) '
      
      IF @Weight IS NOT NULL AND @Weight <> '0'
			SET @SQLWhere = @SQLWhere + ' And (Weight LIKE ''' + @Weight + ''')'
		ELSE IF @Weight = '0'
			SET @SQLWhere = @SQLWhere + ' And (Weight IS NULL) '
 
 
 ----------
       IF @SizeWeight2 IS NOT NULL AND @SizeWeight2 <> '0'
			SET @SQLWhere = @SQLWhere + ' And (SizeWeight2 LIKE ''' + @SizeWeight2 + ''')'
		ELSE IF @SizeWeight2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (SizeWeight2 IS NULL) '
      
      IF @Size2 IS NOT NULL AND @Size2 <> '0'
			SET @SQLWhere = @SQLWhere + ' And (Size2 LIKE ''' + @Size2 + ''')'
		ELSE IF @Size2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (Size2 IS NULL) '
      
      IF @Weight2 IS NOT NULL AND @Weight2 <> '0'
			SET @SQLWhere = @SQLWhere + ' And (Weight2 LIKE ''' + @Weight2 + ''')'
		ELSE IF @Weight2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (Weight2 IS NULL) '
 
 
      IF @Thread2 IS NOT NULL AND @Thread2 <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Thread2 LIKE ''' + @Thread2 + ''')'
      ELSE IF @Thread2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (Thread2 IS NULL) '


      IF @Connection2 IS NOT NULL AND @Connection2 <> '0'
         SET @SQLWhere = @SQLWhere + ' And (Connection2 LIKE ''' + @Connection2 + ''')'
      ELSE IF @Connection2 = '0'
			SET @SQLWhere = @SQLWhere + ' And (Connection2 IS NULL) '

  -------------
 
 
 
      IF @FieldList IS NULL and @date is null
         SET @SQLQuery = 'SELECT * FROM vw_INVSTK2 WHERE ' + @SQLWhere
      ELSE 
        if @FieldList IS NULL and @date is not  null
        begin
        

          SET @SQLQuery = 'SELECT * FROM #t WHERE ' + @SQLWhere
        
        end
        else 
         if @FieldList IS not NULL and @date is not  null
         
           SET @SQLQuery = 'SELECT ' + @FieldList
             + ' FROM #t WHERE ' + @SQLWhere
         else
            SET @SQLQuery = 'SELECT ' + @FieldList
             + ' FROM vw_INVSTK2 WHERE ' + @SQLWhere
 
      --IF @FieldList IS NULL 
      --   SET @SQLQuery = 'SELECT * FROM vw_INVSTK WHERE ' + @SQLWhere
      --ELSE 
      --   SET @SQLQuery = 'SELECT ' + @FieldList
      --       + ' FROM vw_INVSTK WHERE ' + @SQLWhere
             
             
             
             

      IF @GroupBy IS NOT NULL 
         SET @SQLQuery = @SQLQuery + ' Group By ' + @GroupBy

      EXECUTE sp_Executesql @SQLQuery

      PRINT @SQLQuery
                
      IF @@ERROR <> 0 
         GOTO ErrorHandler
      SET NoCount OFF
      RETURN ( 0 )
  
      ErrorHandler:
      RETURN ( @@ERROR )
         


GO


